import 'package:flutter/material.dart';
import '../core/utils/formatters.dart';
class StatCard extends StatelessWidget{
  final String label;final double value;final IconData icon;final Color color;final bool emphasized;
  const StatCard({super.key,required this.label,required this.value,required this.icon,required this.color,this.emphasized=false});
  @override Widget build(BuildContext context)=>Card(color:emphasized?color.withOpacity(.08):Colors.white,child:Padding(padding:const EdgeInsets.all(18),child:Row(children:[
    Container(width:46,height:46,decoration:BoxDecoration(color:color.withOpacity(.12),borderRadius:BorderRadius.circular(14)),child:Icon(icon,color:color)),const SizedBox(width:14),
    Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(label,style:TextStyle(color:Colors.grey.shade600)),const SizedBox(height:5),Text(money(value),style:const TextStyle(fontSize:22,fontWeight:FontWeight.w900))]))
  ])));
}
