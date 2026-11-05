import 'package:flutter/material.dart';
const supportedNexoraThemes = <String>{'amoled', 'light', 'pink_amoled', 'custom'};
String normalizeNexoraTheme(String? value) => supportedNexoraThemes.contains(value) ? value! : 'amoled';
abstract final class NexoraColors {
 static const bg=Color(0xFF000000), surface=Color(0xFF0B0B10), surfaceRaised=Color(0xFF14141C);
 static const text=Color(0xFFF5F5FA), textMuted=Color(0xFF9A9AAE), textFaint=Color(0xFF62627A), hairline=Color(0x1AFFFFFF);
 static const violet=Color(0xFF7C5CFF), cyan=Color(0xFF3DD9FF), pink=Color(0xFFFF5CA8), amber=Color(0xFFFFB86B);
 static const like=Color(0xFFFF4D6D), success=Color(0xFF38E8A5), danger=Color(0xFFFF5C5C);
 static const brandGradient=[violet,pink,amber], coolGradient=[violet,cyan];
 static const black=bg, deep=bg, elevated=surfaceRaised, raised=surfaceRaised, white=text, secondaryText=textMuted, mutedText=textFaint, border=hairline, silver=cyan;
}
abstract final class NexoraSpacing { static const xs=4.0,sm=8.0,md=12.0,lg=16.0,xl=20.0,xxl=24.0,xxxl=32.0,screen=16.0; }
abstract final class NexoraRadius { static const input=12.0,card=20.0,sheet=28.0,pill=999.0; }
abstract final class NexoraTheme {
 static ThemeData get amoled=>_build(Brightness.dark,NexoraColors.bg,NexoraColors.surface,NexoraColors.surfaceRaised,NexoraColors.violet);
 static ThemeData get light=>_build(Brightness.light,const Color(0xFFF4F4F8),Colors.white,const Color(0xFFECECF3),NexoraColors.violet);
 static ThemeData get pinkAmoled=>_build(Brightness.dark,NexoraColors.bg,NexoraColors.surface,NexoraColors.surfaceRaised,NexoraColors.pink);
 static ThemeData custom(Color accent)=>_build(Brightness.dark,NexoraColors.bg,NexoraColors.surface,NexoraColors.surfaceRaised,accent);
 static ThemeData _build(Brightness brightness,Color background,Color surface,Color raised,Color accent) {
  final dark=brightness==Brightness.dark, fg=dark?NexoraColors.text:const Color(0xFF0E0E14), muted=dark?NexoraColors.textMuted:const Color(0xFF686879), line=dark?NexoraColors.hairline:const Color(0x1A000000);
  final scheme=ColorScheme.fromSeed(seedColor:accent,brightness:brightness,primary:accent,onPrimary:Colors.white,secondary:NexoraColors.cyan,surface:surface,error:NexoraColors.danger);
  final body=TextStyle(color:fg,fontSize:15,height:1.45);
  return ThemeData(useMaterial3:true,brightness:brightness,colorScheme:scheme,scaffoldBackgroundColor:background,canvasColor:background,dividerColor:line,
   appBarTheme:AppBarTheme(backgroundColor:background,foregroundColor:fg,surfaceTintColor:Colors.transparent,elevation:0,titleTextStyle:TextStyle(color:fg,fontSize:22,fontWeight:FontWeight.w700)),
   cardTheme:CardThemeData(color:surface,elevation:0,margin:EdgeInsets.zero,surfaceTintColor:Colors.transparent,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(20),side:BorderSide(color:line))),
   inputDecorationTheme:InputDecorationTheme(filled:true,fillColor:raised,hintStyle:TextStyle(color:muted),labelStyle:TextStyle(color:muted),contentPadding:const EdgeInsets.symmetric(horizontal:16,vertical:15),
    border:OutlineInputBorder(borderRadius:BorderRadius.circular(12),borderSide:BorderSide(color:line)),enabledBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(12),borderSide:BorderSide(color:line)),focusedBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(12),borderSide:BorderSide(color:accent,width:1.5))),
   navigationBarTheme:NavigationBarThemeData(backgroundColor:Colors.transparent,indicatorColor:accent.withValues(alpha:.18),elevation:0,height:68,labelBehavior:NavigationDestinationLabelBehavior.alwaysShow,
    iconTheme:WidgetStateProperty.resolveWith((s)=>IconThemeData(color:s.contains(WidgetState.selected)?accent:muted,size:23)),labelTextStyle:WidgetStateProperty.resolveWith((s)=>TextStyle(color:s.contains(WidgetState.selected)?fg:muted,fontSize:11,fontWeight:FontWeight.w500))),
   filledButtonTheme:FilledButtonThemeData(style:FilledButton.styleFrom(backgroundColor:accent,foregroundColor:Colors.white,minimumSize:const Size(48,52),textStyle:const TextStyle(fontSize:15,fontWeight:FontWeight.w700),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16)))),
   outlinedButtonTheme:OutlinedButtonThemeData(style:OutlinedButton.styleFrom(foregroundColor:fg,side:BorderSide(color:line),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16)))),
   textButtonTheme:TextButtonThemeData(style:TextButton.styleFrom(foregroundColor:accent)),iconTheme:IconThemeData(color:muted),
   textTheme:Typography.material2021().black.apply(bodyColor:fg,displayColor:fg,fontFamily:'IBM Plex Sans Arabic').copyWith(displayLarge:TextStyle(color:fg,fontSize:32,fontWeight:FontWeight.w700),titleLarge:TextStyle(color:fg,fontSize:22,fontWeight:FontWeight.w700),titleMedium:TextStyle(color:fg,fontSize:17,fontWeight:FontWeight.w600),bodyLarge:body,bodyMedium:body,bodySmall:TextStyle(color:muted,fontSize:13),labelSmall:TextStyle(color:muted,fontSize:11,fontWeight:FontWeight.w500)));
 }
}