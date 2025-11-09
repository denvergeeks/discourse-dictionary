import { withPluginApi } from "discourse/lib/plugin-api";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { htmlSafe } from "@ember/template";
import Component from "@ember/component";

function customizePost(api) {
  const dialog = api.container.lookup("service:dialog");
  const siteSettings = api.container.lookup("service:site-settings");
  const currentUser = api.getCurrentUser();

  api.renderAfterWrapperOutlet(
    "post-content-cooked-html",
    class DictionaryMeaningComponent extends Component {
      get shouldRender() {
        const post = this.post;
        
        // Only show on first post
        if (post?.post_number !== 1) {
          return false;
        }

        // Only show if there's a current user
        if (!currentUser) {
          return false;
        }

        // Check trust level if configured
        const minTrustLevel = siteSettings?.discourse_dictionary_min_trust_level || 0;
        if (currentUser.trust_level < minTrustLevel) {
          return false;
        }

        return true;
      }

      openDictionaryPrompt = () => {
        const post = this.post;

        dialog.dialog({
          message: htmlSafe(
            '<div class="dictionary-prompt">' +
              '<p>Enter a word to add its dictionary meaning to this topic:</p>' +
              '<input type="text" id="dictionary-word-input" class="ember-text-field" placeholder="Enter a word" style="width: 100%; padding: 8px;" />' +
            '</div>'
          ),
          title: "Add Dictionary Meaning",
          buttons: [
            {
              label: "Cancel",
              class: "btn-default"
            },
            {
              label: "Add Meaning",
              class: "btn-primary",
              action: () => {
                this.handleAddMeaning(post);
              }
            }
          ]
        });
      };

      handleAddMeaning = (post) => {
        const wordInput = document.getElementById("dictionary-word-input");
        const word = wordInput ? wordInput.value.trim() : "";

        if (!word) {
          dialog.alert({
            message: "Please enter a word",
            title: "Error"
          });
          return;
        }

        ajax("/discourse-dictionary/add_meaning", {
          type: "POST",
          data: {
            word: word,
            post_id: post.id
          }
        })
          .then((result) => {
            if (result.success) {
              dialog.alert({
                message: htmlSafe(result.message || "Dictionary meaning added successfully!"),
                title: "Success"
              });
            } else {
              dialog.alert({
                message: htmlSafe(result.message || "Failed to add dictionary meaning"),
                title: "Error"
              });
            }
          })
          .catch(popupAjaxError);
      };

      // Define the template using the layout property
      layout = (hbs`
        {{#if this.shouldRender}}
          <div class="dictionary-meaning-section">
            <button
              class="btn btn-default add-dictionary-meaning"
              {{action this.openDictionaryPrompt}}
            >
              Add Dictionary Meaning
            </button>
          </div>
        {{/if}}
      `);
    }
  );
}

export default {
  name: "discourse-dictionary",

  initialize(container) {
    withPluginApi("1.0.0", (api) => {
      customizePost(api);
    });
  }
};
