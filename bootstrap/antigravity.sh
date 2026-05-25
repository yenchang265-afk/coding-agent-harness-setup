# Antigravity CLI installer. Sourced by install.sh; provides install_antigravity.
# Antigravity is Gemini-CLI-based and natively supports the SKILL.md format, so:
#   rules   -> ~/.gemini/GEMINI.md (its global context file)
#   skills  -> ~/.gemini/antigravity/skills/<name>/SKILL.md (bundle + vendored)
# Note: ~/.gemini/GEMINI.md is shared with Gemini CLI's global context, so the
# assembled rules apply to both. Override the skills root with ANTIGRAVITY_SKILLS
# if your install uses a different path (e.g. ~/.gemini/skills).

install_antigravity() {
  local home_g="$TARGET_HOME/.gemini"
  local skills_dir="${ANTIGRAVITY_SKILLS:-$home_g/antigravity/skills}"

  # 1) rules -> global GEMINI.md (shared with Gemini CLI)
  assemble_rules "$home_g/GEMINI.md"

  # 2) bundle + vendored SKILL.md skills -> global skills dir
  link_all_skills "$skills_dir"

  ok "Antigravity CLI configured (rules: $home_g/GEMINI.md, skills: $skills_dir)"
}
