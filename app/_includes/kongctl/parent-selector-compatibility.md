{:.info}
> **Compatibility:** In affected releases, including v1.21.0, `!ref` on
root-level portal and API child parent selectors can silently omit children
from plans. 
> In sync mode, this can schedule declared live children for
deletion. 
> Use a plain parent ref, such as `portal: docs-portal`, or nest the
child under its parent, until you use a release containing the fix for
[issue #2633](https://github.com/Kong/kongctl/issues/2633).
> Continue using `!ref` for API relationship fields such as `portal_id`.
> <br><br>
> {{site.ai_gateway}} child parent selectors, such as `ai_gateway`, support `!ref`
and don't require this workaround.
