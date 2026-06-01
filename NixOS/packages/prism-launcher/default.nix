{ prismlauncher, prismlauncher-unwrapped }:

let
  unwrapped-cracked = prismlauncher-unwrapped.overrideAttrs (oldAttrs: {
    pname = "prism-launcher-unwrapped";

    postPatch = (oldAttrs.postPatch or "") + ''
            echo "Applying clean substituteInPlace overrides for offline support..."

            # Null-route API connections
            substituteInPlace launcher/minecraft/MinecraftInstance.cpp \
              --replace-warn 'args << "-Duser.language=en";' \
                             'args << "-Duser.language=en";
            args << "-Dminecraft.api.auth.host=https://nope.invalid";
            args << "-Dminecraft.api.account.host=https://nope.invalid";
            args << "-Dminecraft.api.session.host=https://nope.invalid";
            args << "-Dminecraft.api.services.host=https://nope.invalid";'

            # Bypass DRM and online ownership checks
            substituteInPlace launcher/minecraft/auth/AccountList.cpp \
              --replace-warn 'return false;' 'return true;'

            substituteInPlace launcher/minecraft/auth/MinecraftAccount.h \
              --replace-warn 'bool ownsMinecraft() const { return data.type != AccountType::Offline && data.minecraftEntitlement.ownsMinecraft; }' \
                             'bool ownsMinecraft() const { return true; }'

            # Transform the anyAccountIsValid check to true so offline mode flows naturally
            substituteInPlace launcher/LaunchController.cpp \
              --replace-warn 'accounts->anyAccountIsValid()' 'true'

            # Offline Account UI in decideAccount()
            substituteInPlace launcher/LaunchController.cpp \
              --replace-warn 'ProfileSelectDialog selectDialog(tr("Which account would you like to use?"), ProfileSelectDialog::GlobalDefaultCheckbox,' \
                             'if (accounts->count() == 0) {
                    ChooseOfflineNameDialog dialog(tr("No account found. Please enter a username to create an offline account."), m_parentWidget);
                    dialog.setWindowTitle(tr("Create Offline Account"));
                    if (dialog.exec() == QDialog::Accepted) {
                        const MinecraftAccountPtr account = MinecraftAccount::createOffline(dialog.getUsername());
                        if (account) {
                            account->login()->start();
                            accounts->addAccount(account);
                            m_accountToUse = account;
                            accounts->setDefaultAccount(account);
                        }
                    }
                } else {
                    ProfileSelectDialog selectDialog(tr("Which account would you like to use?"), ProfileSelectDialog::GlobalDefaultCheckbox,'

            # Close the else block injected above cleanly
            sed -i '/accounts->setDefaultAccount(m_accountToUse);/{N;s/}/}\n        }/}' launcher/LaunchController.cpp

            # Add the necessary include
            sed -i '/#include "minecraft\/auth\/AccountList.h"/a #include "minecraft\/auth\/MinecraftAccount.h"' launcher/LaunchController.cpp

            # Add the abort check specifically in login(), avoiding the decideAccount() in reauthenticateAccount()
          substituteInPlace launcher/LaunchController.cpp \
            --replace-warn '    decideAccount();

    LaunchDecision decision = decideLaunchMode();' \
                           '    decideAccount();
          if (!m_accountToUse) {
              emitAborted();
              return;
          }

    LaunchDecision decision = decideLaunchMode();'

            # Replace decideLaunchMode body completely
            sed -i '/LaunchDecision LaunchController::decideLaunchMode()/,/^}/c\
      LaunchDecision LaunchController::decideLaunchMode()\n{\n    m_actualLaunchMode = LaunchMode::Normal;\n    return LaunchDecision::Continue;\n}' launcher/LaunchController.cpp

            # Branding
            substituteInPlace program_info/CMakeLists.txt \
              --replace-warn 'set(Launcher_DisplayName "Prism Launcher")' 'set(Launcher_DisplayName "Prism Launcher (FORK)")'
    '';
  });

in

prismlauncher.override {
  prismlauncher-unwrapped = unwrapped-cracked;
}
