import { apiInitializer } from "discourse/lib/api";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

export default apiInitializer((api) => {
  const dialog = api.container.lookup("service:dialog");

  api.onToolbarCreate((toolbar) => {
    toolbar.addButton({
      id: "discourse-dictionary",
      group: "extras",
      icon: "book",
      title: "Insert Dictionary Word",
      perform: (e) => {
        showDictionaryModal(dialog, e);
      }
    });
  });

  function showDictionaryModal(dialog, toolbarEvent) {
    let firstDialogInstance = null;

    dialog.alert({
      message: `<div class="dictionary-prompt">
        <p>Enter a word to add its dictionary meaning:</p>
        <input type="text" id="dictionary-word-input" class="ember-text-field" placeholder="Enter a word" style="width: 100%; padding: 8px;" />
      </div>`,
      title: "Add Dictionary Meaning",
      buttons: [
        { label: "Cancel", class: "btn-default" },
        {
          label: "Search Definitions",
          class: "btn-primary",
          action: () => {
            const wordInput = document.getElementById("dictionary-word-input");
            const word = wordInput ? wordInput.value.trim() : "";
            if (!word) {
              dialog.alert({ message: "Please enter a word", title: "Error" });
              return false;
            }
            getMeanings(word).then((meanings) => {
              if (meanings && meanings.length > 0) {
                showMeaningsModal(dialog, meanings, word, toolbarEvent);
              } else {
                dialog.alert({
                  message: `No definitions found for "${word}"`,
                  title: "No Results"
                });
              }
            });
          }
        }
      ]
    });
  }

  function getMeanings(word) {
    // Call the correct endpoint: /discourse-dictionary/word
    return ajax("/discourse-dictionary/word", {
      type: "GET",
      data: { word }
    })
      .then((response) => {
        if (response.word_definitions && response.word_definitions.definitions) {
          return response.word_definitions.definitions;
        }
        return response.definitions || [];
      })
      .catch((error) => {
        popupAjaxError(error);
        return [];
      });
  }

  function showMeaningsModal(dialog, meanings, word, toolbarEvent) {
    const meaningsHtml = meanings
      .map((meaning, index) => {
        const definition = meaning.definition || meaning;
        const lexical_category = meaning.lexical_category || "noun";

        return `
          <div class="meaning-item">
            <label class="meaning-checkbox">
              <input
                type="radio"
                name="meaning"
                value="${definition}"
                onchange="window.selectedMeaning = ${index}; window.selectedDefinition = '${definition.replace(/"/g, '\\\\"')}';"
              />
              <span class="meaning-text">
                <strong>${lexical_category}</strong><br/>
                ${definition}
              </span>
            </label>
          </div>
        `;
      })
      .join("");

    dialog.alert({
      message: `
        <div class="select-meaning-popup">
          <h3>${word}</h3>
          <div class="meanings-list">
            ${meaningsHtml}
          </div>
        </div>
      `,
      title: "Select Definition",
      buttons: [
        { label: "Cancel", class: "btn-default" },
        {
          label: "Insert Meaning",
          class: "btn-primary",
          action: () => {
            if (window.selectedMeaning !== null && window.selectedMeaning !== undefined) {
              const meaning = meanings[window.selectedMeaning];
              const definition = meaning.definition || meaning;
              const lexical_category = meaning.lexical_category || "noun";

              toolbarEvent.applySurround(
                `[dict meaning="${definition}" lexical="${lexical_category}"]`,
                "[/dict]",
                "dictionary_meaning"
              );
              // Remove the error by just letting the dialog close naturally
              // The dialog will auto-close after the action completes
            } else {
              dialog.alert({ message: "Please select a definition", title: "Error" });
              return false;
            }
          }
        }
      ]
    });
  }
});
