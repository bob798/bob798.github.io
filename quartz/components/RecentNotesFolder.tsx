import { QuartzComponent, QuartzComponentConstructor, QuartzComponentProps } from "./types"
import { FullSlug, SimpleSlug, resolveRelative } from "../util/path"
import { QuartzPluginData } from "../plugins/vfile"
import { byDateAndAlphabetical } from "./PageList"
import { GlobalConfiguration } from "../cfg"
import { classNames } from "../util/lang"

interface Options {
  title: string
  limit: number
  filter: (f: QuartzPluginData) => boolean
  sort: (f1: QuartzPluginData, f2: QuartzPluginData) => number
  defaultOpen: boolean
}

const defaultOptions = (cfg: GlobalConfiguration): Options => ({
  title: "最近更新",
  limit: 5,
  filter: () => true,
  sort: byDateAndAlphabetical(cfg),
  defaultOpen: true,
})

export default ((userOpts?: Partial<Options>) => {
  const RecentNotesFolder: QuartzComponent = ({
    allFiles,
    fileData,
    displayClass,
    cfg,
  }: QuartzComponentProps) => {
    const opts = { ...defaultOptions(cfg), ...userOpts }
    const pages = allFiles.filter(opts.filter).sort(opts.sort).slice(0, opts.limit)

    return (
      <div class={classNames(displayClass, "recent-folder")}>
        <details open={opts.defaultOpen}>
          <summary class="recent-folder-summary">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              width="12"
              height="12"
              viewBox="5 8 14 8"
              fill="none"
              stroke="currentColor"
              stroke-width="2"
              stroke-linecap="round"
              stroke-linejoin="round"
              class="recent-folder-icon"
            >
              <polyline points="6 9 12 15 18 9"></polyline>
            </svg>
            <span class="recent-folder-title">{opts.title}</span>
          </summary>
          <ul class="recent-folder-list">
            {pages.map((page) => {
              const title = page.frontmatter?.title ?? "Untitled"
              const href = resolveRelative(fileData.slug!, page.slug!) as SimpleSlug
              return (
                <li>
                  <a href={href} class="internal">
                    {title}
                  </a>
                </li>
              )
            })}
          </ul>
        </details>
      </div>
    )
  }

  RecentNotesFolder.css = `
.recent-folder {
  font-size: 0.85rem;
}
.recent-folder details > summary {
  list-style: none;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 0.25rem;
  padding: 0.2rem 0;
  user-select: none;
  font-weight: 500;
  color: var(--dark);
}
.recent-folder details > summary::-webkit-details-marker {
  display: none;
}
.recent-folder details > summary::marker {
  display: none;
  content: "";
}
.recent-folder .recent-folder-icon {
  transition: transform 0.15s ease;
  flex-shrink: 0;
  color: var(--gray);
}
.recent-folder details[open] > summary .recent-folder-icon {
  transform: rotate(0deg);
}
.recent-folder details:not([open]) > summary .recent-folder-icon {
  transform: rotate(-90deg);
}
.recent-folder .recent-folder-title {
  font-size: 0.85rem;
}
.recent-folder-list {
  list-style: none;
  margin: 0.2rem 0 0.5rem;
  padding-left: 1rem;
  border-left: 1px solid var(--lightgray);
  margin-left: 0.3rem;
}
.recent-folder-list > li {
  margin: 0.3rem 0;
  font-size: 0.8rem;
  line-height: 1.3;
}
.recent-folder-list > li > a.internal {
  background-color: transparent;
  color: var(--darkgray);
  text-decoration: none;
}
.recent-folder-list > li > a.internal:hover {
  color: var(--dark);
  text-decoration: underline;
}
`

  return RecentNotesFolder
}) satisfies QuartzComponentConstructor
