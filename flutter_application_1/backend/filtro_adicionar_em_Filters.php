<?php
/**
 * No seu app/Config/Filters.php existente:
 *
 * 1. Dentro da propriedade $aliases, adicione:
 *
 *    public array $aliases = [
 *        // ...os que já existem (csrf, toolbar, etc.)
 *        'tokenAuth' => \App\Filters\TokenAuthFilter::class,
 *    ];
 *
 * 2. Não precisa adicionar em $globals nem $methods — o filtro é
 *    aplicado só no grupo de rotas 'api' lá no Routes.php
 *    (['filter' => 'tokenAuth']), então as rotas públicas
 *    (registro/login) continuam sem exigir token.
 */
