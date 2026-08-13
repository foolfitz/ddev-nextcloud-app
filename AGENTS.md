# AGENTS.md

- 回答與專案文件請使用台灣正體中文。
- 不得執行 `sudo`、`su`、`doas` 或需要 root 權限的系統修改。
- 這是 DDEV add-on；安裝後的檔案會落在使用端專案的 `.ddev/`。
- 所有安裝到使用端專案的 add-on 管理檔案都必須包含 `#ddev-generated`。
- Nextcloud app 原始碼位於使用端專案根目錄，產生的 Nextcloud core 位於 `nextcloud/`。
- 修改 shell 指令後至少執行 `bash -n commands/web/* nextcloud-app/lib.sh`。
- 修改 add-on 封裝後，應以 `ddev add-on get <本目錄>` 驗證；可行時再執行 Bats 整合測試。
