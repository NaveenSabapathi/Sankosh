import type { Metadata, Viewport } from "next";
import "./globals.css";
import { PwaRegister } from "./pwa-register";
export const metadata: Metadata={title:"Sankosh — Personal finance, made mindful",description:"Track bills, EMIs, budgets, shared expenses and investments in one private personal finance workspace.",manifest:"/manifest.webmanifest",appleWebApp:{capable:true,statusBarStyle:"black-translucent",title:"Sankosh"},icons:{icon:"/favicon.svg",apple:"/favicon.svg"}};
export const viewport:Viewport={themeColor:"#09090d",colorScheme:"dark",width:"device-width",initialScale:1,viewportFit:"cover"};
export default function RootLayout({children}:Readonly<{children:React.ReactNode}>){return <html lang="en" className="dark"><body>{children}<PwaRegister/></body></html>}
