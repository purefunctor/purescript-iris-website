import factorialSource from "#src/Website/Landing/Example/Factorial.purs?raw";
import factorialOutput from "#output/Website.Landing.Example.Factorial/index.js?raw";
import shapeSource from "#src/Website/Landing/Example/Shape.purs?raw";
import shapeOutput from "#output/Website.Landing.Example.Shape/index.js?raw";
import effectSource from "#src/Website/Landing/Example/Effect.purs?raw";
import effectOutput from "#output/Website.Landing.Example.Effect/index.js?raw";
import stylesSource from "#src/Website/Landing/Example/Styles.purs?raw";
import stylesOutput from "#output/Website.Landing.Example.Styles/index.js?raw";

const withoutSourceMap = output => output.replace(/\n\/\/# sourceMappingURL=.*\n?$/, "\n");

const matching = (code, pattern) =>
  code.split("\n").flatMap((line, index) => (pattern.test(line) ? [index + 1] : []));

const compiled = (source, output, sourcePattern, outputPattern) => {
  const javascript = withoutSourceMap(output);
  return {
    source,
    output: javascript,
    sourceHighlight: matching(source, sourcePattern),
    outputHighlight: matching(javascript, outputPattern),
  };
};

export const examples = {
  factorial: compiled(factorialSource, factorialOutput, /= factorial/, /while \(true\)|continue;/),
  shape: compiled(shapeSource, shapeOutput, /^\s+[A-Z]\w*.*->/, /tag === |tag: /),
  effect: compiled(effectSource, effectOutput, /<-|Console\.log/, /\$action(\$\d+)?\(\);|\)\(\);/),
  styles: compiled(stylesSource, stylesOutput, /StyleX\.create/, /\$stylex\.(create|props)/),
};
