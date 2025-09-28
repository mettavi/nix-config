{ config, inputs, ... }:
{
  userConfig.users = {
    "myadmin" = {
      # defaults to username "timotheos"
      # pull encrypted "soft" secrets from private git rep
      name = inputs.secrets.name;
      description = "This is main admin account of the system, whose default username on most systems is \"timotheos\"";
      email = inputs.secrets.email.gitHub;
    };
  };
  _module.args.username = config.userConfig.users.myadmin.username;
}
