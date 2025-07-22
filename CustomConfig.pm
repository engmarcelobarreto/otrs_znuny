# /CustomConfig.pm
package Kernel::Config;

sub Load {
    my $Self = shift;

    # ---
    # Adiciona o caminho base para o proxy reverso.
    # Isso garante que o Znuny saiba que está rodando em /servicedesk
    # e gere todos os links e URLs de recursos corretamente.
    # ---
    $Self->{'ScriptAlias'} = '/servicedesk/';

    return 1;
}

1;