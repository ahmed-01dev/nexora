import 'package:flutter/material.dart';
import '../../core/theme/nexora_theme.dart';
import '../../core/widgets/nexora_glass.dart';
class DesignGalleryScreen extends StatefulWidget { const DesignGalleryScreen({super.key}); @override State<DesignGalleryScreen> createState()=>_DesignGalleryScreenState(); }
class _DesignGalleryScreenState extends State<DesignGalleryScreen> {
 String _theme='amoled'; bool _rtl=true;
 ThemeData get _data=>switch(_theme){'light'=>NexoraTheme.light,'pink_amoled'=>NexoraTheme.pinkAmoled,'custom'=>NexoraTheme.custom(const Color(0xFF38E8A5)),_=>NexoraTheme.amoled};
 @override Widget build(BuildContext context)=>Theme(data:_data,child:Directionality(textDirection:_rtl?TextDirection.rtl:TextDirection.ltr,child:Scaffold(
 appBar:AppBar(title:const Text('NEXORA · Design Gallery'),actions:[IconButton(onPressed:()=>setState(()=>_rtl=!_rtl),icon:const Icon(Icons.format_textdirection_r_to_l))]),
 body:ListView(padding:const EdgeInsets.all(16),children:[
 Wrap(spacing:8,children:['amoled','light','pink_amoled','custom'].map((v)=>ChoiceChip(label:Text(v),selected:_theme==v,onSelected:(_)=>setState(()=>_theme=v))).toList()),
 const SizedBox(height:20),Text('Aurora Glass',style:Theme.of(context).textTheme.displaySmall),const Text('Content stays solid. Glass floats above it.'),const SizedBox(height:24),
 _heading('Floating glass variants'),Wrap(spacing:10,runSpacing:10,children:[const NexoraGlass(child:Icon(Icons.search)),const NexoraGlass(variant:GlassVariant.clear,child:Icon(Icons.play_arrow)),NexoraGlass(variant:GlassVariant.tinted,child:const Icon(Icons.add),accent:Theme.of(context).colorScheme.primary)]),
 const SizedBox(height:24),_heading('Buttons'),Row(children:[Expanded(child:FilledButton.icon(onPressed:(){},icon:const Icon(Icons.bolt),label:const Text('Primary'))),const SizedBox(width:10),Expanded(child:OutlinedButton.icon(onPressed:(){},icon:const Icon(Icons.tune),label:const Text('Secondary')))]),
 const SizedBox(height:24),_heading('Inputs'),const TextField(decoration:InputDecoration(prefixIcon:Icon(Icons.search),hintText:'Search people, posts, tags')),
 const SizedBox(height:24),_heading('Solid content card'),Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:Theme.of(context).colorScheme.surface,borderRadius:BorderRadius.circular(20),border:Border.all(color:Theme.of(context).dividerColor)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
 const Row(children:[CircleAvatar(child:Icon(Icons.person)),SizedBox(width:10),Expanded(child:Text('NEXORA Creator',style:TextStyle(fontWeight:FontWeight.w700))),Icon(Icons.more_horiz)]),const SizedBox(height:14),
 Container(height:150,decoration:BoxDecoration(borderRadius:BorderRadius.circular(16),gradient:const LinearGradient(colors:NexoraColors.coolGradient)),child:const Center(child:Icon(Icons.image_outlined,size:48,color:Colors.white))),
 const SizedBox(height:12),const Text('A calmer social space, designed around what matters.'),const SizedBox(height:10),const Row(children:[Icon(Icons.favorite_border),SizedBox(width:5),Text('128'),SizedBox(width:18),Icon(Icons.mode_comment_outlined),SizedBox(width:5),Text('24'),Spacer(),Icon(Icons.share_outlined)])])),
 const SizedBox(height:24),_heading('Chat bubbles'),Align(alignment:AlignmentDirectional.centerStart,child:const NexoraGlass(variant:GlassVariant.clear,radius:20,child:Text('Hey! Welcome to NEXORA.'))),
 const SizedBox(height:8),Align(alignment:AlignmentDirectional.centerEnd,child:DecoratedBox(decoration:BoxDecoration(gradient:const LinearGradient(colors:NexoraColors.coolGradient),borderRadius:BorderRadius.circular(20)),child:const Padding(padding:EdgeInsets.all(14),child:Text('This feels much better',style:TextStyle(color:Colors.white))))),
 const SizedBox(height:24),_heading('Story ring'),Row(children:[Container(padding:const EdgeInsets.all(3),decoration:const BoxDecoration(shape:BoxShape.circle,gradient:LinearGradient(colors:NexoraColors.brandGradient)),child:const CircleAvatar(radius:27,child:Icon(Icons.person))),const SizedBox(width:12),const Text('Unseen story ring')]),
 const SizedBox(height:24),_heading('Skeleton'),Container(height:14,width:160,decoration:BoxDecoration(color:Theme.of(context).colorScheme.surfaceContainerHighest,borderRadius:BorderRadius.circular(99))),const SizedBox(height:10),Container(height:90,decoration:BoxDecoration(color:Theme.of(context).colorScheme.surfaceContainerHighest,borderRadius:BorderRadius.circular(18))),
 const SizedBox(height:24),_heading('Floating toast'),const NexoraGlass(radius:999,child:Row(children:[Icon(Icons.check_circle,color:NexoraColors.success),SizedBox(width:8),Expanded(child:Text('Your changes are saved')),Icon(Icons.close)])),
 const SizedBox(height:20),Text('Direction: ${_rtl?'RTL':'LTR'} · Theme: $_theme'),
 ]))));
 Widget _heading(String s)=>Padding(padding:const EdgeInsets.only(bottom:12),child:Text(s,style:Theme.of(context).textTheme.titleMedium));
}