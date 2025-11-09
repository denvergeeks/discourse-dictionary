import { registerMarkdownItFeature } from "discourse/lib/markdown-it-features";

registerMarkdownItFeature((md, options) => {
  // Enable the plugin
  if (!options.features["discourse-dictionary-enabled"]) {
    return;
  }

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
      startToken.content = content;
      startToken.nesting = 1;

      endToken.type = "span_close";
      endToken.tag = "span";
      endToken.content = "";
      endToken.nesting = -1;

      return true;
    },
  });

  return {
    priority: 40,
    rules: ["dict"],
  };
});
