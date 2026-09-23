"""MkDocs hook — name Material's search dialog (axe: aria-dialog-name), at build time.

Server-side: the aria-label lands in the shipped HTML — no client-JS loading/timing
dependency. Enable in mkdocs.yml (path relative to mkdocs.yml = repo root):

    hooks:
      - search_a11y_hook.py
"""

def on_post_page(output, page=None, config=None, **kwargs):
    needle  = 'data-md-component="search" role="dialog"'
    labeled = needle + ' aria-label="Search"'
    # Guard on the labeled DIALOG DIV specifically — NOT on `aria-label="Search"` anywhere,
    # because Material's search <input> already carries that string on every page.
    if needle in output and labeled not in output:
        output = output.replace(needle, labeled, 1)
        if not getattr(on_post_page, "_logged", False):
            on_post_page._logged = True
    return output