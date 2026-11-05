import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/nexora_theme.dart';
enum GlassVariant { regular, clear, tinted }
/// Floating overlay only. Do not wrap feed cards, list rows, or text blocks.
class NexoraGlass extends StatelessWidget {
 const NexoraGlass({super.key,required this.child,this.variant=GlassVariant.regular,this.radius=NexoraRadius.pill,this.padding=const EdgeInsets.all(12),this.accent,this.blur=28,this.lowDataMode=false,this.reduceTransparency=false,this.border=true});
 final Widget child; final GlassVariant variant; final double radius,blur; final EdgeInsetsGeometry padding; final Color? accent; final bool lowDataMode,reduceTransparency,border;
 @override Widget build(BuildContext context) {
  final dark=Theme.of(context).brightness==Brightness.dark,tint=accent??Theme.of(context).colorScheme.primary,fallback=lowDataMode||reduceTransparency;
  final opacity=switch(variant){GlassVariant.regular=>dark ? .075 : .62,GlassVariant.clear=>dark ? .035 : .42,GlassVariant.tinted=>dark ? .17 : .72};
  final fill=variant==GlassVariant.tinted?Color.alphaBlend(tint.withValues(alpha:.16),dark?NexoraColors.surfaceRaised:Colors.white):Colors.white.withValues(alpha:opacity);
  return ClipRRect(borderRadius:BorderRadius.circular(radius),child:BackdropFilter(filter:ImageFilter.blur(sigmaX:fallback?0:blur.clamp(24,40),sigmaY:fallback?0:blur.clamp(24,40)),child:Container(padding:padding,
   decoration:BoxDecoration(color:fallback?(dark?NexoraColors.surfaceRaised.withValues(alpha:.92):Colors.white.withValues(alpha:.94)):fill,borderRadius:BorderRadius.circular(radius),
    border:border?Border.all(color:dark?Colors.white.withValues(alpha:.13):Colors.white.withValues(alpha:.75)):null,
    gradient:variant==GlassVariant.tinted?LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[tint.withValues(alpha:.25),tint.withValues(alpha:.07)]):null,
    boxShadow:[BoxShadow(color:Colors.black.withValues(alpha:dark ? .28 : .08),blurRadius:24,offset:const Offset(0,8)),BoxShadow(color:tint.withValues(alpha:.08),blurRadius:26)]),child:child)));
 }
}