#!/usr/bin/env bats

setup_file() {
  export ADDON_ROOT
  ADDON_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." && pwd)"
  export PROJECT_NAME="test-ddev-nextcloud-app"
  export TEST_ROOT
  TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/${PROJECT_NAME}.XXXXXX")"
  export DDEV_NONINTERACTIVE=true
  export DDEV_NO_INSTRUMENTATION=true

  cp -R "${ADDON_ROOT}/tests/testdata/test_nextcloud_app/." "${TEST_ROOT}/"
  cd "${TEST_ROOT}"

  ddev delete -Oy "${PROJECT_NAME}" >/dev/null 2>&1 || true
  ddev config \
    --project-name="${PROJECT_NAME}" \
    --project-type=php \
    --docroot=nextcloud \
    --webserver-type=apache-fpm \
    --php-version=8.4 \
    --database=mariadb:11.4 \
    --nodejs-version=24
  ddev add-on get "${ADDON_ROOT}"
  ddev start -y
}

teardown_file() {
  ddev delete -Oy "${PROJECT_NAME}" >/dev/null 2>&1 || true
  if [ -z "${GITHUB_ENV:-}" ]; then
    rm -rf -- "${TEST_ROOT}"
  else
    printf 'TEST_ROOT=%s\n' "${TEST_ROOT}" >> "${GITHUB_ENV}"
  fi
}

@test "add-on files and merged configuration are installed" {
  cd "${TEST_ROOT}"

  [ -x .ddev/commands/web/nc-setup ]
  [ -x .ddev/commands/web/cron ]
  [ -x .ddev/commands/web/nc-link ]
  [ -x .ddev/commands/web/nc-app-exec ]
  [ -x .ddev/commands/web/occ ]
  grep -Fq "/nextcloud/" .gitignore

  run ddev utility configyaml --full-yaml
  [ "${status}" -eq 0 ]
  [[ "${output}" == *"NEXTCLOUD_VERSION=stable34"* ]]
}

@test "Nextcloud 34 is installed and the fixture app is enabled" {
  cd "${TEST_ROOT}"

  run ddev nc-setup
  [ "${status}" -eq 0 ]
  [[ "${output}" == *"Nextcloud app ddev_test_app 已啟用。"* ]]

  run ddev occ status
  [ "${status}" -eq 0 ]
  [[ "${output}" == *"version: 34."* ]]

  run ddev occ app:list --enabled
  [ "${status}" -eq 0 ]
  [[ "${output}" == *"ddev_test_app"* ]]

  run ddev nc-setup stable34
  [ "${status}" -eq 0 ]
  [[ "${output}" == *"正在套用 Nextcloud 資料庫升級"* ]]
}

@test "app commands run from the installed app path" {
  cd "${TEST_ROOT}"

  run ddev nc-app-exec php -r 'echo getcwd();'
  [ "${status}" -eq 0 ]
  [[ "${output}" == *"/nextcloud/apps-extra/ddev_test_app"* ]]

  run ddev exec test -L nextcloud/apps-extra/ddev_test_app/appinfo
  [ "${status}" -eq 0 ]
}

@test "the Nextcloud web endpoint responds" {
  cd "${TEST_ROOT}"

  primary_url="$(ddev describe -j | jq -r '.raw.primary_url')"
  run curl -fsS "${primary_url}/status.php"
  [ "${status}" -eq 0 ]
  [[ "${output}" == *'"installed":true'* ]]
  [[ "${output}" == *'"version":"34.'* ]]
}

@test "removing the add-on cleans managed files but keeps the core worktree" {
  cd "${TEST_ROOT}"

  run ddev add-on remove ddev-nextcloud-app
  [ "${status}" -eq 0 ]
  [ ! -e .ddev/commands/web/nc-setup ]
  [ ! -e .ddev/config.nextcloud-app.yaml ]
  [ -f nextcloud/version.php ]
  ! grep -Fq "# BEGIN ddev-nextcloud-app" .gitignore
}
