{ module, platform ? "qemu-x86_64", ... }:
(import ./appliance.nix { inherit platform; }).buildApp module
