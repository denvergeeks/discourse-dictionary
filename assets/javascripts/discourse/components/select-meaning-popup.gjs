import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { inject as service } from "@ember/service";
import { on } from "@ember/modifier";
import { fn } from "@ember/helper";
import { eq } from "truth-helpers";

export default class SelectMeaningPopupComponent extends Component {
  @service modal;
  @service currentUser;

  @tracked loading = false;
  @tracked errorMessage = null;
  @tracked meanings = [];
  @tracked selectedDefinition = null;
  @tracked selectedMeaning = null;

  get word() {
    return this.args.model?.word;
  }

  get insertDisabled() {
    return !this.selectedDefinition;
  }

  constructor() {
    super(...arguments);
    this.loadMeanings();
  }

  async loadMeanings() {
    this.loading = true;
    try {
      const response = await ajax("/discourse-dictionary/word", {
        data: { word: this.word }
      });
      this.meanings = response?.word_definitions?.definitions || [];
    } catch (error) {
      popupAjaxError(error);
      this.errorMessage = "Failed to load word definitions";
    } finally {
      this.loading = false;
    }
  }

  @action
  changeDefinition(definition) {
    this.selectedDefinition = definition;
    this.selectedMeaning = this.meanings.find(
      (meaning) => meaning.definition === definition
    );
  }

  @action
  insertMeaning() {
    if (!this.selectedMeaning) return;

    const { definition, lexical_category } = this.selectedMeaning;
    
    if (this.args.toolbarEvent) {
      this.args.toolbarEvent.applySurround(
        `[dict meaning="${definition}" lexical="${lexical_category}"]`,
        "[/dict]",
        "dictionary_meaning"
      );
    }

    this.modal.close();
  }

  @action
  closeModal() {
    this.modal.close();
  }

  <template>
    <div class="select-meaning-popup">
      <h3>{{this.word}}</h3>

      {{#if this.loading}}
        <div class="loading-indicator">Loading definitions...</div>
      {{else if this.errorMessage}}
        <div class="alert alert-error">{{this.errorMessage}}</div>
      {{else if this.meanings.length}}
        <div class="meanings-list">
          {{#each this.meanings key="definition" as |meaning|}}
            <div class="meaning-item">
              <label class="meaning-checkbox">
                <input
                  type="radio"
                  name="meaning"
                  value={{meaning.definition}}
                  checked={{eq this.selectedDefinition meaning.definition}}
                  {{on "change" (fn this.changeDefinition meaning.definition)}}
                />
                <span class="meaning-text">
                  <strong>{{meaning.lexical_category}}</strong>
                  {{meaning.definition}}
                </span>
              </label>
            </div>
          {{/each}}
        </div>
      {{else}}
        <p class="no-meanings">No definitions found for "{{this.word}}"</p>
      {{/if}}

      <div class="modal-buttons">
        <button
          type="button"
          class="btn btn-default"
          {{on "click" this.closeModal}}
        >
          Cancel
        </button>
        <button
          type="button"
          class="btn btn-primary"
          disabled={{this.insertDisabled}}
          {{on "click" this.insertMeaning}}
        >
          Insert Meaning
        </button>
      </div>
    </div>
  </template>
}
