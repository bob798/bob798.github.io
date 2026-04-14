import { QuartzConfig } from "./quartz/cfg"
import * as Plugin from "./quartz/plugins"

const config: QuartzConfig = {
  configuration: {
    pageTitle: "Bob's Garden",
    pageTitleSuffix: " | Bob",
    enableSPA: true,
    enablePopovers: false,
    analytics: {
      provider: "plausible",
    },
    locale: "zh-CN",
    baseUrl: "bob798.github.io",
    ignorePatterns: ["private", "templates", ".obsidian"],
    defaultDateType: "created",
    theme: {
      fontOrigin: "googleFonts",
      cdnCaching: true,
      typography: {
        header: { name: "Inter", weights: [400, 600] },
        body: { name: "Inter", weights: [400, 500], includeItalic: true },
        code: "JetBrains Mono",
      },
      colors: {
        lightMode: {
          light: "#ffffff",
          lightgray: "#f0f0f0",
          gray: "#cccccc",
          darkgray: "#333333",
          dark: "#1a1a1a",
          secondary: "#555555",
          tertiary: "#888888",
          highlight: "rgba(0, 0, 0, 0.04)",
          textHighlight: "#fff8dc88",
        },
        darkMode: {
          light: "#111111",
          lightgray: "#222222",
          gray: "#555555",
          darkgray: "#cccccc",
          dark: "#eeeeee",
          secondary: "#aaaaaa",
          tertiary: "#888888",
          highlight: "rgba(255, 255, 255, 0.05)",
          textHighlight: "#fff8dc22",
        },
      },
    },
  },
  plugins: {
    transformers: [
      Plugin.FrontMatter(),
      Plugin.CreatedModifiedDate({
        priority: ["frontmatter", "git", "filesystem"],
      }),
      Plugin.SyntaxHighlighting({
        theme: {
          light: "min-light",
          dark: "min-dark",
        },
        keepBackground: false,
      }),
      Plugin.ObsidianFlavoredMarkdown({ enableInHtmlEmbed: false }),
      Plugin.GitHubFlavoredMarkdown(),
      Plugin.TableOfContents({ maxDepth: 3, collapseByDefault: true }),
      Plugin.CrawlLinks({ markdownLinkResolution: "shortest" }),
      Plugin.Description(),
      Plugin.Latex({ renderEngine: "katex" }),
    ],
    filters: [Plugin.RemoveDrafts()],
    emitters: [
      Plugin.AliasRedirects(),
      Plugin.ComponentResources(),
      Plugin.ContentPage(),
      Plugin.FolderPage(),
      Plugin.TagPage(),
      Plugin.ContentIndex({
        enableSiteMap: true,
        enableRSS: true,
      }),
      Plugin.Assets(),
      Plugin.Static(),
      Plugin.Favicon(),
      Plugin.NotFoundPage(),
      Plugin.CustomOgImages(),
    ],
  },
}

export default config
