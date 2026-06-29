# ADO work item MCP tools

Tool IDs may be prefixed by the server name (`azure-devops_…`, `ado_…`, `mcp_ado_…`).
Match by purpose.

| Step | Tool (canonical id) | Key params | Notes |
|------|---------------------|------------|-------|
| Query assigned items | `wit_query_work_items` | wiql | `WHERE [Assigned To] = @Me AND [State] NOT IN (...)` |
| List items (simple) | `wit_list_work_items` | project, assignedTo, states | Alternative to raw WIQL |
| Get one item | `wit_get_work_item` | id, expand=all | Full fields incl. description, acceptance criteria, parent |
| Create item | `wit_create_work_item` | project, type, fields | Set Title, Description, AssignedTo, relations |
| Update item | `wit_update_work_item` | id, operations (JSON Patch) | Add parent link after creation if needed |

## Parent link format

```json
{
  "rel": "System.LinkTypes.Hierarchy-Reverse",
  "url": "https://<org>.visualstudio.com/<project>/_apis/wit/workItems/<parentId>"
}
```

## OFF-LIMITS
- Never delete or close work items.
- Never change the assigned-to field of existing items.
- Never modify items owned by other users without explicit user confirmation.
