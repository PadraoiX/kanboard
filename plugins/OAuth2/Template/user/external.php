<h3><i class="fa fa-lock fa-fw" aria-hidden="true"></i>Conta</h3>

<div class="panel">
    <?php if ($this->user->isCurrentUser($user['id'])): ?>
        <?php if (empty($user['oauth2_user_id'])): ?>
            <?= $this->url->link(t('Link OAuth2 account'), 'OAuthController', 'handler', array('plugin' => 'OAuth2'), true) ?>
        <?php else: ?>
            <?= $this->url->link('Desvincular conta', 'OAuthController', 'unlink', array('backend' => 'OAuth2'), true) ?>
        <?php endif ?>
    <?php else: ?>
        <?= empty($user['oauth2_user_id']) ? 'Conta não vinculada.' : t('Conta vinculada.') ?>
    <?php endif ?>
</div>
