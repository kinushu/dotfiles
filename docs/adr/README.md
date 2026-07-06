# Architecture Decision Records

このディレクトリには、dotfilesプロジェクトのアーキテクチャ決定記録（ADR）を保存する。

## 形式

[MADR](https://adr.github.io/madr/)形式を採用。

## 命名規則

`YYYY-MM-DD_タイトル.md`

例: `2026-01-01_review.md`

## ADR一覧

| 日付 | タイトル | ステータス |
|------|---------|-----------|
| 2026-01-02 | deploy dry-run と link check 機能追加 | proposed |
| 2026-01-21 | install_anthropic_skills_plugin | proposed |
| 2026-01-23 | add_directory_link_mode | proposed |
| 2026-01-29 | add_playwright_for_js_rendering | proposed |
| 2026-01-29 | Claude CLI実行中のmacOSスリープ防止 | accepted |
| 2026-02-03 | share_skills_between_claude_and_codex | superseded |
| 2026-02-25 | unify_ai_tool_skills_and_instructions | accepted |
| 2026-02-28 | improve_check_links_with_directory_links_and_diff_output | accepted |
| 2026-03-04 | move_user_scripts_to_config_bin | accepted |
| 2026-03-25 | スキル実行時の曖昧性確認ポリシーと .md プレビュー方針を統一 | proposed |
| 2026-03-29 | improve_claude_code_config_based_on_best_practices | proposed |
| 2026-04-01 | npmサプライチェーン攻撃対策としてのパッケージマネージャセキュリティ設定導入 | accepted |
| 2026-04-02 | generate_local_codex_config_from_template_on_deploy | proposed |
| 2026-04-15 | add_json_progress_output_to_review_by_codex | proposed |
| 2026-04-17 | inline_fence_code_template_for_docker_support | proposed |
| 2026-04-23 | adopt_empirical_prompt_tuning_for_skill_quality | accepted |
| 2026-07-03 | split_deploy_and_init_by_os_with_mitamae_roles | accepted |
