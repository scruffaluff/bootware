module.exports = {
  base: "/bootware/",
  plugins: [
    ["vuepress-plugin-code-copy", { color: "#FFFFFF", staticIcon: true }],
  ],
  themeConfig: {
    docsDir: "docs",
    editLinks: true,
    lastUpdated: "Last Updated",
    nav: [
      { text: "Home", link: "/" },
      { text: "Install", link: "/install/" },
      { text: "Software", link: "/software/" },
      { text: "Config", link: "/config/" },
    ],
    repo: "https://github.com/scruffaluff/bootware",
    smoothScroll: true,
  },
};
