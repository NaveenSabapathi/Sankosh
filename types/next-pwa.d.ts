declare module "next-pwa" { import type { NextConfig } from "next"; export default function withPWAInit(options:Record<string,unknown>):(config:NextConfig)=>NextConfig }
