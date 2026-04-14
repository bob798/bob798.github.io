import { PageLayout, SharedLayout } from "./quartz/cfg"
import * as Component from "./quartz/components"

const explorerSortFn = (a: any, b: any) => {
  if (a.isFolder && !b.isFolder) return -1
  if (!a.isFolder && b.isFolder) return 1
  if (!a.isFolder && !b.isFolder) {
    return b.displayName.localeCompare(a.displayName, undefined, {
      numeric: true,
      sensitivity: "base",
    })
  }
  return a.displayName.localeCompare(b.displayName, undefined, {
    numeric: true,
    sensitivity: "base",
  })
}

// components shared across all pages
export const sharedPageComponents: SharedLayout = {
  head: Component.Head(),
  header: [],
  afterBody: [
    Component.Comments({
      provider: "giscus",
      options: {
        repo: "bob798/bob798.github.io",
        repoId: "MDEwOlJlcG9zaXRvcnk3NDc0OTY2OA==",
        category: "General",
        categoryId: "DIC_kwDOBHSW5M4C6y1G",
        mapping: "pathname",
        strict: false,
        reactionsEnabled: true,
        inputPosition: "bottom",
      },
    }),
  ],
  footer: Component.Footer({
    links: {
      GitHub: "https://github.com/bob798",
      Speakeasy: "https://github.com/bob798/speakeasy",
      "AI Handbook": "https://github.com/bob798/ai-handbook",
    },
  }),
}

// components for pages that display a single page (e.g. a single note)
export const defaultContentPageLayout: PageLayout = {
  beforeBody: [
    Component.ConditionalRender({
      component: Component.Breadcrumbs(),
      condition: (page) => page.fileData.slug !== "index",
    }),
    Component.ArticleTitle(),
    Component.ContentMeta(),
    Component.TagList(),
  ],
  left: [
    Component.PageTitle(),
    Component.MobileOnly(Component.Spacer()),
    Component.Flex({
      components: [
        {
          Component: Component.Search(),
          grow: true,
        },
        { Component: Component.Darkmode() },
        { Component: Component.ReaderMode() },
      ],
    }),
    Component.Explorer({
      folderDefaultState: "open",
      sortFn: explorerSortFn,
    }),
  ],
  right: [
    Component.Graph(),
    Component.DesktopOnly(Component.TableOfContents()),
    Component.Backlinks(),
  ],
}

// components for pages that display lists of pages (e.g. tags or folders)
export const defaultListPageLayout: PageLayout = {
  beforeBody: [Component.Breadcrumbs(), Component.ArticleTitle(), Component.ContentMeta()],
  left: [
    Component.PageTitle(),
    Component.MobileOnly(Component.Spacer()),
    Component.Flex({
      components: [
        {
          Component: Component.Search(),
          grow: true,
        },
        { Component: Component.Darkmode() },
      ],
    }),
    Component.Explorer({
      folderDefaultState: "open",
      sortFn: explorerSortFn,
    }),
  ],
  right: [],
}
