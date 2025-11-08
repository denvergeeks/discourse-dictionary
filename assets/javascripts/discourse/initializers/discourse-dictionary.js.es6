import { apiInitializer } from "discourse/lib/api";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { htmlSafe } from "@ember/template";

export default apiInitializer("1.0.0", (api) => {
  const siteSettings = api.container.lookup("service:site-settings");
  const dialog = api.container.lookup("service:dialog");
  
  api.decorateWidget("post-contents:after-cooked", (helper) => {
    const post = helper.getModel();
    const currentUser = api.getCurrentUser();
    
    // Only show on first post
    if (post.get("post_number") !== 1) {
      return;
    }
    
    // Check trust level
    if (!currentUser) {
      return;
    }
    
    const minTrustLevel = siteSettings.discourse_dictionary_min_trust_level || 0;
    if (currentUser.trust_level < minTrustLevel) {
      return;
    }
    
    return helper.h("button.btn.btn-default.add-dictionary-meaning", {
      onclick: () => {
        showDictionaryPrompt(dialog, post, helper);
      }
    }, "Add Dictionary Meaning");
  });
});

function showDictionaryPrompt(dialog, post, helper) {
  // Create a custom dialog with an input field
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
          const wordInput = document.getElementById("dictionary-word-input");
          const word = wordInput ? wordInput.value.trim() : "";
          
          if (!word) {
            dialog.alert({
              message: "Please enter a word",
              title: "Error"
            });
            return;
          }
          
          // Make AJAX request to add dictionary meaning
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
                
                // Refresh the post to show the new content
                if (helper && helper.widget) {
                  helper.widget.scheduleRerender();
                }
              } else {
                dialog.alert({
                  message: htmlSafe(result.message || "Failed to add dictionary meaning"),
                  title: "Error"
                });
              }
            })
            .catch(popupAjaxError);
        }
      }
    ]
  });
}
