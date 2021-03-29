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
      { text: "Installation", link: "/install/" },
      { text: "Configuration", link: "/config/" },
    ],
    repo: "https://github.com/wolfgangwazzlestrauss/bootware",
    smoothScroll: true,
  },
};
