import { QuartzComponent, QuartzComponentConstructor, QuartzComponentProps } from "./types"
import { classNames } from "../util/lang"
import style from "./styles/profile.scss"

interface ProfileOptions {
  name: string
  tagline?: string
  avatar?: string
  links?: Record<string, string>
}

export default ((opts: ProfileOptions) => {
  const Profile: QuartzComponent = ({ displayClass }: QuartzComponentProps) => {
    return (
      <div class={classNames(displayClass, "profile-card")}>
        <div class="profile-header">
          {opts.avatar && <img class="profile-avatar" src={opts.avatar} alt={opts.name} />}
          <div class="profile-meta">
            <span class="profile-name">{opts.name}</span>
            {opts.tagline && <span class="profile-tagline">{opts.tagline}</span>}
          </div>
        </div>
        {opts.links && Object.keys(opts.links).length > 0 && (
          <div class="profile-links">
            {Object.entries(opts.links).map(([label, href]) => (
              <a href={href} target="_blank" rel="noopener noreferrer">
                {label}
              </a>
            ))}
          </div>
        )}
      </div>
    )
  }

  Profile.css = style
  return Profile
}) satisfies QuartzComponentConstructor<ProfileOptions>
