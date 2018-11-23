{
  services.openssh = {
    enable = true;
    forwardX11 = false;

    passwordAuthentication = false; # Only allow authorized keys
  };

  users.users.root.openssh.authorizedKeys.keys = [
     "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQD+uUrTPYVdoZiNIiQyuj9IUjO36EVERX8BPh8OVlFaEK9bYq3SUT4ocohjQjbwrFP3BeZ1cgwWGc5LKuLFcdtnEPToHdxlG39T5nxMZGuRkNLnlkqG+dszl5ObQ5Xm+kf7g2OQjmivOO+kdboXKGY5UZAFCJid/2RT8mxv4MyYtfbqW3vxPHt+LvBslxMEpiKd7xlKiZU2sEUvmyQfyhYV53HPwONXI89oshBpD4vcMlm35lvjC/Zk3R40E2QxFrpTlrUH41hMYCnz1sbJBvjYG/UntCxuSobI51EU0HgYdB0yT7AG4KbvlAzUKbEQZZti7HFkdFYdl2mZ2J+SYUQuhwmnatO+SRBsPxRmsxopzIA0qMn+AB1TPBC2rhsHex+fP9V3ClccGrDHgYSAEsY7AdZhTaO4xX6N5bE4HqMJYgB4f/zDaxugzeyoVlFr9mMjOjEkbxX8t07iRQQ0mxSZmaboUg40WfKObCI5Rrb/zMDT0xX4XmfNqD2TuIqz0FKT8+VXmfPXkHpQPlP77+rL9w2WZWt40AR2X9/upYnWZOsFIlNaj2PEGdiiv+knxujWzRrMOxEXQds9hSgwMpxd1nvUYhHrjhLzXI6VduwlOLjEMGXWmMxYkWKQes0gqAdC+i8qk8CNMH1EaC1crjQjrezHeaGFwfdxqLmXHUFozw== travis@athougies.net"
  ];
}
