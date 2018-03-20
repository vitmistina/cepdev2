({
  doInit: function(cmp) {
    const colorsArray = ["light", "medium", "dark", "medium"];
    const array = cmp.get("v.text").split(" ");
    const wordsGroupLength = array.length < 6 ? 1 : array.length < 13 ? 2 : 3;
    const output = array.map(
      (word, index) =>
        new Object({
          string: word.concat(index === array.length - 1 ? "" : " "),
          class:
            colorsArray[
              Math.floor(index / wordsGroupLength) % colorsArray.length
            ]
        })
    );

    cmp.set("v.gradientWords", output);
  }
});
