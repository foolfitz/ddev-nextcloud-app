<?php

declare(strict_types=1);

/**
 * SPDX-FileCopyrightText: 2026 ddev-nextcloud-app contributors
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

namespace OCA\DdevTestApp\AppInfo;

use OCP\AppFramework\App;
use OCP\AppFramework\Bootstrap\IBootContext;
use OCP\AppFramework\Bootstrap\IBootstrap;
use OCP\AppFramework\Bootstrap\IRegistrationContext;

final class Application extends App implements IBootstrap {
	public const APP_ID = 'ddev_test_app';

	public function __construct() {
		parent::__construct(self::APP_ID);
	}

	public function register(IRegistrationContext $context): void {
	}

	public function boot(IBootContext $context): void {
	}
}
