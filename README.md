# DDEV Nextcloud App

這是一套以「Nextcloud app 專案為中心」的 DDEV 開發腳手架，概念取自
[`ddev/ddev-drupal-contrib`](https://github.com/ddev/ddev-drupal-contrib)。
它不會把 app 塞進另一個主要 repository；app 原始碼仍留在目前 repository
根目錄，Nextcloud core 則是可重建的本機工作區。

## 提供的功能

- 預設取得 Nextcloud `v33.0.8` 與 `3rdparty` submodule。
- 從 `appinfo/info.xml` 自動讀取 app ID。
- 將 app 根目錄的檔案連結到 `nextcloud/apps-extra/<app-id>`。
- 自動安裝 Nextcloud、設定 MariaDB、開發模式與 DDEV Mailpit。
- 安裝完成後自動啟用目前 app。
- 提供 `ddev occ`、`ddev cron`、`ddev nc-link`、`ddev nc-setup` 與
  `ddev nc-app-exec`。
- 支援使用既有的 Nextcloud core clone，方便離線或 core/app 聯合開發。

## 目錄配置

```text
my_nextcloud_app/
├── appinfo/
├── lib/
├── src/
├── tests/
├── composer.json
├── package.json
├── .ddev/                         # 安裝 add-on 後產生
└── nextcloud/                     # 可重建，不納入 Git
    ├── apps/
    ├── apps-extra/
    │   └── my_nextcloud_app/      # 指向 repository 根目錄內容的 symlink farm
    ├── config/
    └── occ
```

symlink farm 只排除 `.git/`、`.ddev/` 與 `nextcloud/`，因此 app 的
`vendor/`、`node_modules/`、測試與建置輸出仍能從 Nextcloud app 路徑存取，
但不會形成遞迴連結。

## 安裝

先在 Nextcloud app repository 根目錄設定 DDEV：

```bash
ddev config \
  --project-type=php \
  --docroot=nextcloud \
  --webserver-type=apache-fpm \
  --php-version=8.4 \
  --database=mariadb:11.4 \
  --nodejs-version=24
```

接著安裝這個 add-on。開發本 repository 時可直接使用本機路徑：

```bash
ddev add-on get /home/jiajun/Projects/ddev-nextcloud-app
ddev start
ddev nc-setup
```

`ddev nc-setup` 第一次執行時會要求輸入本機管理員密碼；密碼不會寫入
repository。若在非互動環境執行，它會產生一組隨機密碼並顯示一次。

安裝完成後：

```bash
ddev launch
ddev occ status
ddev occ app:list --enabled
```

## 使用本機 Nextcloud 33.0.8 原始碼

若主機已有 `/home/jiajun/OSSII/NC_server/nc33`，可在 `ddev start` 前以
本機 clone 建立工作區，省去重新下載 core Git objects：

```bash
git clone --local --branch v33.0.8 /home/jiajun/OSSII/NC_server/nc33 nextcloud
ddev start
ddev nc-setup
```

`nc-setup` 會補齊尚未初始化的 `3rdparty` submodule、建立開發設定並安裝
Nextcloud。它不會修改原始的 `nc33` worktree。

## 日常開發

先在 app repository 根目錄安裝 app 自己的相依套件：

```bash
ddev composer install
ddev exec npm ci
ddev nc-link
```

`nc-link` 也會在每次 `ddev start` 時自動執行。新增 repository 根層檔案、
`vendor/` 或 `node_modules/` 後，可手動再執行一次。

需要讓測試從真正的 Nextcloud app 路徑執行時，使用：

```bash
ddev nc-app-exec vendor/bin/phpunit -c phpunit.xml
ddev nc-app-exec composer run cs:check
ddev nc-app-exec vendor/bin/phpstan analyze
ddev nc-app-exec npm test
```

這對 bootstrap 內含 `../../../lib/base.php` 的 Nextcloud app 測試尤其重要。

常用管理指令：

```bash
ddev occ app:disable <app-id>
ddev occ app:enable <app-id>
ddev occ maintenance:repair
ddev cron
ddev occ log:watch
ddev xdebug
ddev xdebug off
```

## 切換 Nextcloud core 版本

第一次建立環境時可直接指定 branch 或 tag：

```bash
ddev nc-setup v33.0.8
ddev nc-setup v34.0.2
```

既有 core 也可用相同指令切換。腳本會拒絕覆寫有追蹤中修改的 core
worktree，並在切換後執行 `occ upgrade`。

資料庫升級通常不可逆。跨 major 版本前應先建立快照，而且不要把已升級的
資料庫直接拿去跑較舊的 Nextcloud：

```bash
ddev snapshot --name=before-nextcloud-upgrade
ddev nc-setup v34.0.2
```

## 自訂

預設值：

- Core repository：`https://github.com/nextcloud/server.git`
- Core ref：`v33.0.8`
- 管理員帳號：`admin`

可在 `.ddev/config.local.yaml` 覆寫 web environment：

```yaml
web_environment:
  - NEXTCLOUD_VERSION=v33.0.8
  - NEXTCLOUD_CORE_REPOSITORY=https://github.com/nextcloud/server.git
  - NEXTCLOUD_ADMIN_USER=admin
```

管理員密碼刻意不放在設定檔。自動化環境若必須提供固定密碼，可在
`.ddev/config.local.yaml` 加入 `NEXTCLOUD_ADMIN_PASSWORD`，但該檔案不應
提交。

## 驗證 add-on

靜態檢查：

```bash
bash -n commands/web/* nextcloud-app/lib.sh
```

完整測試會建立暫時 DDEV 專案、clone Nextcloud 33.0.8、安裝 fixture app，
最後驗證 HTTP、`occ` 與 app 啟用狀態：

```bash
bats tests/test.bats
```

## 與現有 Nextcloud DDEV 專案的差異

現有方案多半以「執行一個 Nextcloud 站台」為主，或直接包裝官方 FPM
image。本 add-on 的目標則是 app contribution workflow：目前 app
repository 是主要工作區、core 可切換、測試能從 app 安裝路徑執行。

## 授權

Apache-2.0
