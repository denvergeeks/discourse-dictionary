export function setup(helper) {
  if (!helper.markdownIt) {
    return;
  }

  helper.allowList("span.dictionary-word");
  helper.allowList("span.dictionary-trigger");

  helper.registerOptions((opts, siteSettings) => {
    opts.features[
      "dictionary-block"
    ] = !!siteSettings.discourse_dictionary_enabled;
  });

  helper.registerPlugin((md) => {
    md.inline.bbcode.ruler.push("dict", {
      tag: "dict",
      wrap(startToken, endToken, info, content) {
        startToken.type = "span_open";
        startToken.tag = "span";
        startToken.attrs = [
          ["class", "dictionary-word dictionary-trigger"],
          ["data-definition", info.attrs.meaning],
          ["data-lexical", info.attrs.lexical],
          ["style", "cursor: pointer; font-weight: bold; text-decoration: underline; text-decoration-style: dotted; color: #0087be;"],
        ];
        startToken.content = content;  // Use the content as-is (the word)
        startToken.nesting = 1;

        endToken.type = "span_close";
        endToken.tag = "span";
        endToken.content = "";
        endToken.nesting = -1;
        
        return true;
      },
    });
  });
}
