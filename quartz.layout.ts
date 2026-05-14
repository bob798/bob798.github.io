import { PageLayout, SharedLayout } from "./quartz/cfg"
import * as Component from "./quartz/components"

const explorerSortFn = (a: any, b: any) => {
  // folders first
  if (a.isFolder && !b.isFolder) return -1
  if (!a.isFolder && b.isFolder) return 1
  // files: sort by date descending (newest first)
  if (!a.isFolder && !b.isFolder) {
    const aDate = a.data?.date ? new Date(a.data.date).getTime() : 0
    const bDate = b.data?.date ? new Date(b.data.date).getTime() : 0
    if (aDate || bDate) return bDate - aDate
    // fallback: reverse slug order (date-prefixed filenames)
    return b.slugSegment.localeCompare(a.slugSegment, undefined, { numeric: true })
  }
  // folders: alphabetical
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
    Component.DesktopOnly(
      Component.Profile({
        name: "Bob",
        tagline: "后端工程师 → AI 应用工程师",
        links: {
          GitHub: "https://github.com/bob798",
          Email: "mailto:xbb798@gmail.com",
          RSS: "/index.xml",
        },
      }),
    ),
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
      folderDefaultState: "collapsed",
      sortFn: explorerSortFn,
    }),
    Component.DesktopOnly(
      Component.RecentNotesFolder({
        title: "最近更新",
        limit: 5,
        defaultOpen: true,
        filter: (f) => {
          const slug = f.slug ?? ""
          // 排除：结构页（index/about）、folder index、ai-handbook 命名空间、archive 归档、草稿
          if (slug === "index" || slug === "about") return false
          if (slug.endsWith("/index")) return false
          if (slug.startsWith("ai-handbook/")) return false
          if (slug.startsWith("archive/")) return false
          if (slug === "_unpublished-articles") return false
          if (slug.startsWith("tags/")) return false
          return true
        },
      }),
    ),
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
      folderDefaultState: "collapsed",
      sortFn: explorerSortFn,
    }),
  ],
  right: [],
}
