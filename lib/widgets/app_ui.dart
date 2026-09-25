import 'package:flutter/material.dart';

class AppAlerts {
  static void success(BuildContext c,String m)=>_show(c,m,Icons.check_circle_outline,Colors.green);
  static void error(BuildContext c,String m)=>_show(c,m,Icons.error_outline,Colors.red);
  static void info(BuildContext c,String m)=>_show(c,m,Icons.info_outline,Colors.blue);
  static void _show(BuildContext context,String message,IconData icon,Color color){
    ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(SnackBar(
      behavior:SnackBarBehavior.floating,backgroundColor:color,
      content:Row(children:[Icon(icon,color:Colors.white),const SizedBox(width:10),Expanded(child:Text(message))]),
    ));
  }
}

class AppDialogs {
  static Future<bool> confirm(BuildContext context,{required String title,required String message,String confirmText='Eliminar'}) async =>
    await showDialog<bool>(context:context,builder:(context)=>AlertDialog(
      title:Text(title),content:Text(message),actions:[
        TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('Cancelar')),
        FilledButton(onPressed:()=>Navigator.pop(context,true),child:Text(confirmText)),
      ],
    )) ?? false;

  static Future<T?> form<T>(BuildContext context,{required String title,required Widget child})=>showDialog<T>(
    context:context,builder:(context)=>Dialog(insetPadding:const EdgeInsets.all(16),child:ConstrainedBox(
      constraints:const BoxConstraints(maxWidth:520),child:Padding(padding:const EdgeInsets.all(22),child:Column(
        mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.stretch,children:[
          Text(title,style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.w800)),
          const SizedBox(height:18),ConstrainedBox(constraints:BoxConstraints(maxHeight:560),child:SingleChildScrollView(child:child)),
        ],
      )),
    )),
  );
}

class AppField extends StatelessWidget {
  final TextEditingController controller;final String label;final String? hint;final TextInputType? keyboardType;final String? Function(String?)? validator;final bool obscureText;final int maxLines;
  const AppField({super.key,required this.controller,required this.label,this.hint,this.keyboardType,this.validator,this.obscureText=false,this.maxLines=1});
  @override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.only(bottom:14),child:TextFormField(
    controller:controller,keyboardType:keyboardType,validator:validator,obscureText:obscureText,maxLines:maxLines,decoration:InputDecoration(labelText:label,hintText:hint),
  ));
}

class PageHeader extends StatelessWidget {
  final String title,subtitle;final Widget? action;
  const PageHeader({super.key,required this.title,required this.subtitle,this.action});
  @override Widget build(BuildContext context)=>LayoutBuilder(builder:(context,c){
    final heading=Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w900)),const SizedBox(height:6),Text(subtitle,style:TextStyle(color:Colors.grey.shade600))]);
    if(c.maxWidth<620)return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[heading,if(action!=null)...[const SizedBox(height:14),SizedBox(width:double.infinity,child:action!)]]);
    return Row(children:[Expanded(child:heading),if(action!=null)action!]);
  });
}

class EmptyState extends StatelessWidget {
  final String title,message;const EmptyState({super.key,required this.title,required this.message});
  @override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.symmetric(vertical:48),child:Center(child:Column(children:[Icon(Icons.inbox_outlined,size:48,color:Colors.grey.shade400),const SizedBox(height:12),Text(title,style:const TextStyle(fontWeight:FontWeight.w800)),const SizedBox(height:4),Text(message,style:TextStyle(color:Colors.grey.shade600))])));
}
