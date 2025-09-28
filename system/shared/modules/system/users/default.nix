{ config, inputs, ... }:
{
  imports = [ ./user_opts.nix ];

  # list all users managed by the nix system
  nyx.system.userConfig.users = {
    "myadmin" = {
      # defaults to username "timotheos"
      # pull encrypted "soft" secrets from private git rep
      name = inputs.secrets.name;
      description = "This is main admin account of the system, whose default username on most systems is \"timotheos\"";
      email = inputs.secrets.email.gitHub;
    };
  };

  # pass the primary admin user's username to other modules
  _module.args.username = config.nyx.system.userConfig.users.myadmin.username;
}
