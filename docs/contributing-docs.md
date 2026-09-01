# Contributing to this wiki

[← Back to index](README.md)

This page describes how the SpeleoLoc user wiki is put together, so that a new
page looks like the ones already here and a changed screen does not leave the
documentation quietly wrong.

The wiki is written for **cavers using the app**, not for people working on it.
Developer-facing notes live elsewhere in the repository and are deliberately not
linked from here.

## Layout

```
docs/
├── README.md              the index — every page is reachable from it
├── overview.md            what the app is for, and its data model
├── getting-started.md     installation and first launch
├── glossary.md            the vocabulary used throughout
├── contributing-docs.md   this page
├── features/              one page per screen or per subject
├── workflows/             task-oriented walkthroughs
├── screenshots/           the galleries — every screenshot, described
├── images/                the screenshot files themselves
└── ro/                    the Romanian edition, mirroring all of the above
```

`features/` answers *"what does this screen do?"*. `workflows/` answers
*"how do I get this job done?"* and links out to the feature pages rather
than repeating them. If a page starts doing both, split it.

## Page conventions

- Open with `# Page title` in sentence case, a blank line, then the back-link:
  `[← Back to index](../README.md)` from a subdirectory, `(README.md)` from the
  top level.
- Follow with one or two sentences saying what the page covers.
- Use `##` for sections and `###` for sub-sections, and a table wherever you are
  listing fields or options.
- Close with a `## See also` list of three to six related pages.
- Wrap prose at about 78 columns.

## Naming things the way the app does

Every control has an official English label in the app's own translation file.
Look the label up there rather than inventing one, and write a menu path with
arrows: **Settings → General → Show home toolbar**.

The app's default language is **Romanian**; English is selected in
**Settings → General → App language**. That is why the screenshots show
Romanian labels while the English pages use the English ones — the galleries
give both.

Do not name source files, classes, database tables or configuration keys. The
exception is a string the user genuinely types or sees, such as a QR label
template variable.

## Screenshots

Images are stored **once**, in `docs/images/`, and shared by both language
editions. Each one is described **once**, in a gallery page under
`docs/screenshots/`. Feature pages do not embed images — they link to the
gallery entry:

```markdown
> 📷 [The sync log tab](../screenshots/06-sync-and-sharing.md#ftp-sync-log-tab) — each step of the last run, newest first.
```

This keeps a screen's description in one place, keeps the feature pages
readable, and means a re-taken screenshot only has to be described again once.

### Adding a screenshot

1. Capture it on a phone in portrait orientation, with the app in its normal
   state — no half-open menus, no debug overlays if you can avoid them.
2. Crop the device status bar and navigation bar away, scale it to **640 px
   wide**, and save it as a progressive JPEG at quality ~86. Nothing inside the
   app window may be retouched.
3. Name it after what it shows, not when it was taken:
   `cave-map-measure-distance.jpg`, never `Screenshot_20260901_024828.jpg`.
   The name is a permanent anchor, so pick one that survives a re-capture.
4. Add an entry to the right gallery page with an `<a id="the-slug"></a>` anchor
   above the heading, the image, a one-line caption, a short description of what
   the screen does, and — where the shot is Romanian — a collapsible list
   mapping the visible wording to English.
5. Link it from the feature pages it illustrates.

Replacing a shot means overwriting the file and revising its gallery entry. The
anchor and the file name stay put, so no link breaks.

## The Romanian edition

`docs/ro/` mirrors the English tree file for file: the same file names, the same
headings, the same anchors, so a link translates by swapping the path prefix.
Only the prose is translated.

Romanian pages must use the **exact wording the app shows**, taken from the
app's Romanian translation file — a caver reading the page has the Romanian
interface in front of them, so an invented translation of a button name is
worse than useless. Where a term has no settled Romanian form, give the
Romanian and put the English in brackets on first use.

When you change an English page, change its Romanian counterpart in the same
commit, or say plainly in the commit message that the translation still has to
catch up.

## Keeping the wiki honest

- Check a claim against the app before writing it down. If you cannot confirm
  what a control does, leave it out rather than guessing.
- Say plainly when an action is destructive, irreversible, or visible only in
  debug mode.
- The app is in alpha and moves quickly. A page that has drifted is worth
  fixing even if you only fix one section of it.

## See also

- [Wiki index](README.md)
- [Screenshot gallery](screenshots/README.md)
- [Glossary](glossary.md)
