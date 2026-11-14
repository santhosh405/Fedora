#!/usr/bin/env bash
set -euo pipefail

VAULT="${1:-/home/fuckwindows/Documents/second_brain}"

mk() {
  if [ -e "$1" ]; then cat >/dev/null; echo "  skip   $1"; else cat > "$1"; echo "  create $1"; fi
}

echo "Building vault at: $VAULT"

mkdir -p "$VAULT"/{00_Inbox,01_Projects,02_Areas,03_Resources,04_Archive,05_Daily/Conversations,06_Reviews,_Templates,_Attachments,.obsidian}

mk "$VAULT/.obsidian/app.json" <<'EOF'
{
  "newFileLocation": "folder",
  "newFileFolderPath": "00_Inbox",
  "attachmentFolderPath": "_Attachments",
  "alwaysUpdateLinks": true,
  "useMarkdownLinks": false
}
EOF

mk "$VAULT/.obsidian/daily-notes.json" <<'EOF'
{
  "folder": "05_Daily",
  "format": "YYYY-MM-DD",
  "template": "_Templates/Daily Note",
  "autorun": true
}
EOF

mk "$VAULT/.obsidian/templates.json" <<'EOF'
{
  "folder": "_Templates",
  "dateFormat": "YYYY-MM-DD",
  "timeFormat": "HH:mm"
}
EOF

mk "$VAULT/.obsidian/core-plugins.json" <<'EOF'
["file-explorer","global-search","switcher","graph","backlink","outgoing-link","tag-pane","page-preview","daily-notes","templates","note-composer","command-palette","outline","word-count","file-recovery","properties","bookmarks"]
EOF

mk "$VAULT/Home.md" <<'EOF'
---
type: home
---
# 🧠 Second Brain

## PARA
| Folder | What goes here | Rule |
|---|---|---|
| 00_Inbox | Quick capture, unsorted | Empty it weekly |
| 01_Projects | Goals with an outcome and a deadline | Has an end date |
| 02_Areas | Ongoing responsibilities | No end date, a standard to maintain |
| 03_Resources | Topics of interest and reference | Useful someday |
| 04_Archive | Finished or inactive items | Move here, never delete |

## Daily rhythm
1. Open today's daily note
2. Plan the day, log conversations, capture ideas
3. Evening: fill the end-of-day review
4. Weekly: run **Weekly Review** from `06_Reviews`

## Templates (Ctrl+P → Templates: Insert template)
- Daily Note (applied automatically)
- Conversation Log
- Project
- Area
- Resource
- Weekly Review
- Quick Capture
EOF

mk "$VAULT/00_Inbox/00_Inbox.md" <<'EOF'
# Inbox
Everything new lands here first. Process it weekly into Projects, Areas, Resources, or Archive.
EOF
mk "$VAULT/01_Projects/README.md" <<'EOF'
# Projects
Short-term efforts with a clear outcome and deadline. Use the Project template.
EOF
mk "$VAULT/02_Areas/README.md" <<'EOF'
# Areas
Ongoing responsibilities (Health, Finance, Career, Learning...). Use the Area template.
EOF
mk "$VAULT/03_Resources/README.md" <<'EOF'
# Resources
Reference material and topics of interest. Use the Resource template.
EOF
mk "$VAULT/04_Archive/README.md" <<'EOF'
# Archive
Completed projects, retired areas, old resources.
EOF

mk "$VAULT/_Templates/Daily Note.md" <<'EOF'
---
type: daily
date: {{date:YYYY-MM-DD}}
week: {{date:gggg-[W]ww}}
tags: [daily]
mood:
energy:
---
# {{date:dddd, MMMM D, YYYY}}

## 🎯 Top 3 priorities
1. [ ] 
2. [ ] 
3. [ ] 

## 📅 Schedule


## ✅ Tasks
- [ ] 

## 💬 Conversations
| Time | With | Topic | Key takeaway | Follow-up |
|---|---|---|---|---|
|  |  |  |  |  |

Linked conversations:
- 

## 💡 Ideas & notes


## 📥 Captured today


## 🌙 End-of-day review
- **Wins:** 
- **Lessons:** 
- **Grateful for:** 
- **Tomorrow's first task:** 
EOF

mk "$VAULT/_Templates/Conversation Log.md" <<'EOF'
---
type: conversation
date: {{date:YYYY-MM-DD}}
time: {{time:HH:mm}}
with: 
channel: 
project: 
tags: [conversation]
---
# {{title}}

Daily note: [[{{date:YYYY-MM-DD}}]]

## Context


## Key points
- 

## Decisions made
- 

## Action items
- [ ] 

## Follow-up questions
- 

## Quotes / snippets
> 

## Related
- Project: 
- Area: 
EOF

mk "$VAULT/_Templates/Project.md" <<'EOF'
---
type: project
status: active
created: {{date:YYYY-MM-DD}}
deadline: 
area: 
tags: [project]
---
# {{title}}

## 🎯 Outcome


## 📌 Why it matters


## ✅ Next actions
- [ ] 

## 🗺️ Milestones
| Milestone | Due | Status |
|---|---|---|
|  |  |  |

## 📚 Related resources
- 

## 💬 Conversations
- 

## 📝 Log
- {{date:YYYY-MM-DD}}: Project created
EOF

mk "$VAULT/_Templates/Area.md" <<'EOF'
---
type: area
created: {{date:YYYY-MM-DD}}
review: weekly
tags: [area]
---
# {{title}}

## 🎖️ Standard to maintain


## 🔁 Routines & habits
- 

## 📊 Metrics
| Metric | Target | Current |
|---|---|---|
|  |  |  |

## 🚀 Active projects
- 

## 📚 Resources
- 
EOF

mk "$VAULT/_Templates/Resource.md" <<'EOF'
---
type: resource
created: {{date:YYYY-MM-DD}}
source: 
author: 
topic: 
status: to-read
tags: [resource]
---
# {{title}}

## Summary (in my own words)


## Key ideas
- 

## Quotes
> 

## How I can use this
- Project: 
- Area: 
EOF

mk "$VAULT/_Templates/Weekly Review.md" <<'EOF'
---
type: review
period: {{date:gggg-[W]ww}}
created: {{date:YYYY-MM-DD}}
tags: [review, weekly]
---
# Weekly Review {{date:gggg-[W]ww}}

## 1. Clear the inbox
- [ ] Process everything in 00_Inbox into PARA
- [ ] Review this week's daily notes

## 2. Look back
- **Wins:** 
- **Challenges:** 
- **Lessons:** 
- **Key conversations:** 

## 3. Review PARA
- [ ] Projects: still active? next action defined?
- [ ] Areas: anything neglected?
- [ ] Resources: anything to act on?
- [ ] Archive finished items

## 4. Look ahead
1. 
2. 
3. 
EOF

mk "$VAULT/_Templates/Quick Capture.md" <<'EOF'
---
type: capture
created: {{date:YYYY-MM-DD}} {{time:HH:mm}}
tags: [inbox]
---
# {{title}}

Daily note: [[{{date:YYYY-MM-DD}}]]

## Thought


## Where does this belong?
- [ ] Project: 
- [ ] Area: 
- [ ] Resource: 
EOF

TODAY="$(date +%F)"
mk "$VAULT/05_Daily/$TODAY.md" <<EOF
---
type: daily
date: $TODAY
tags: [daily]
---
# $(date '+%A, %B %-d, %Y')

## 🎯 Top 3 priorities
1. [ ] 
2. [ ] 
3. [ ] 

## 💬 Conversations
| Time | With | Topic | Key takeaway | Follow-up |
|---|---|---|---|---|
|  |  |  |  |  |

## 💡 Ideas & notes

## 🌙 End-of-day review
- **Wins:** 
- **Lessons:** 
EOF

echo
echo "Done. In Obsidian: Open folder as vault -> $VAULT"
