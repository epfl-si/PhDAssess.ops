{ pkgs, lib, config, inputs, ... }:

{
  # https://devenv.sh/basics/
  env.GREET = "PhDAssess.ops";

  packages = with pkgs; [
    # Deploy tools
    python313
    (pkgs.python313.withPackages (ps: with ps; [
      kubernetes
    ]))
    ansible
    openshift

    # dev stack
    docker-compose

    # Zeebe devops operations
    zbctl
   ];

  # https://devenv.sh/languages/
  # languages.rust.enable = true;

  # https://devenv.sh/processes/
  # processes.dev.exec = "${lib.getExe pkgs.watchexec} -n -- ls -la";

  # https://devenv.sh/services/
  # services.postgres.enable = true;

  # https://devenv.sh/scripts/
  scripts.phd = {
    description = "Devops scripting";
    packages = [ pkgs.zx ];
    exec = "zx ./phd.mjs $@";
  };

  scripts.lint-ansible = {
    description = "Lint the Ansible files";
    packages = [ pkgs.ansible-lint ];
    exec = ''
      echo "Linting Ansible files..."
      ansible-lint ./ansible
      echo ""
      echo "Syntax checkin Ansible files..."
      ansible-playbook -i ansible/inventory/dev.yml --syntax-check ./ansible/playbook.yml
      echo "Linting done."
    '';
  };

  # https://devenv.sh/basics/
  enterShell = ''
    echo ""
    echo "🎓 📈 ✅ PhDAssess Operational Environment ⚙️ 🚀"
    echo "=================================="
    echo "👉  Project: epfl-si/PhDAssess.ops"
    echo "📌  Running devenv shell…"
    echo ""
    echo "🔥 You are in the PhDAssess.ops operational environment ⚙️ 🚀"
    echo "   Provided tools: ansible, zx, zbctl, oc, lint-ansible, ..."
    echo "Next:"
    echo "  run the 'phd' command"
    echo "  or use the './phdsible --list-tag' to prepare some deployments."
  '';

  # https://devenv.sh/tasks/
  # tasks = {
  #   "myproj:setup".exec = "mytool build";
  #   "devenv:enterShell".after = [ "myproj:setup" ];
  # };

  # https://devenv.sh/tests/
  #  enterTest = ''
  #    echo "Running tests"
  #    git --version | grep --color=auto "${pkgs.git.version}"
  #  '';

  # https://devenv.sh/git-hooks/
  # git-hooks.hooks.shellcheck.enable = true;

  # See full reference at https://devenv.sh/reference/options/
}
