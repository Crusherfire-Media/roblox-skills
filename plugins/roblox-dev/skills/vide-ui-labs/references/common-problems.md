# Common problems

UI Labs messages and symptoms, their cause, and the fix.

| Symptom or message | Cause | Fix |
|---|---|---|
| The story does not appear, or sits under "Unknown Stories" | The name does not end in `.story`, or the module is outside every storybook's `storyRoots` | Rename it, or move it under the stories folder |
| "Story module errored when required" | An error at the top level of the story or of a module it requires | Read the output for the failing module and line |
| "Could not resolve require ..." or "Invalid path start" | A require alias other than `./`, `../`, `@self`, `@game` | Use one of those forms |
| "Vide story yielded when called." | A wait in the story or in a component body (`WaitForChild`, `task.wait`, an `Async` call) | Move it out, or pass the data in as a prop |
| "attempt to index nil with 'PlayerGui'" or similar | `Players.LocalPlayer` is nil in edit mode | Pass player data in through props |
| A control change does not update the preview | The component reads that prop once | Type the prop `T \| () -> T` and bind it |
| The controls panel lists controls in a jumbled order that changes between reloads | The controls have no `Order`, so they all tie in the panel's default sort | Group them and wrap every group and control in `UILabs.Ordered` |
| "attempt to call a table value" on a control read | The control sits in a group, so the read got the group's table | Read it through its group: `controls.Group.Name()` |
| "cannot use ...() outside a stable or reactive scope" inside a story | The story and its components require different copies of Vide | Require the same Vide module the components use |
| A blur, part, or GUI is left in the place after closing a story | The UI created it outside the story's frame | Gate it behind a prop or `RunService:IsRunning()`, or `cleanup` it; delete the leftovers |
| "The story cleanup errored when called" or "The story cleanup was not found" | The story errored while mounting, so its cleanup never ran | Fix the error; restart Studio if instances or connections leaked |
| A story that worked starts erroring after a component change | The story no longer matches the component's props | Update the story in the same change as the component |
| Edits do not reload the story | Auto reload is off for that tab, or the edit is an unsaved collaborative draft | Turn auto reload on (right-click the tab), or reload by hand |
