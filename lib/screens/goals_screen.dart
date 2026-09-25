import 'package:flutter/material.dart';
import '../providers/app_state.dart';
import '../models/models.dart';
import '../widgets/app_ui.dart';
import '../core/utils/formatters.dart';

class GoalsScreen extends StatelessWidget{
  final AppState state;const GoalsScreen({super.key,required this.state});
  Future<void> form(BuildContext context,{SavingsGoal? item}) async{
    final key=GlobalKey<FormState>();final title=TextEditingController(text:item?.title??'');final target=TextEditingController(text:item==null?'':item.targetAmount.toStringAsFixed(0));final saved=TextEditingController(text:item==null?'':item.savedAmount.toStringAsFixed(0));
    final ok=await AppDialogs.form<bool>(context,title:item==null?'Nueva meta':'Editar meta',child:Form(key:key,child:Column(children:[
      AppField(controller:title,label:'Nombre de la meta',validator:(v)=>(v==null||v.trim().isEmpty)?'Campo obligatorio':null),
      AppField(controller:target,label:'Monto objetivo',keyboardType:const TextInputType.numberWithOptions(decimal:true),validator:(v)=>(double.tryParse(v??'')??0)<=0?'Monto inválido':null),
      AppField(controller:saved,label:'Ahorro reservado',keyboardType:const TextInputType.numberWithOptions(decimal:true),validator:(v)=>(double.tryParse(v??'')??-1)<0?'Monto inválido':null),
      Row(children:[Expanded(child:OutlinedButton(onPressed:()=>Navigator.pop(context,false),child:const Text('Cancelar'))),const SizedBox(width:10),Expanded(child:FilledButton(onPressed:() async{if(!key.currentState!.validate())return;try{await state.saveGoal(SavingsGoal(id:item?.id??'new',title:title.text.trim(),targetAmount:double.parse(target.text),savedAmount:double.parse(saved.text)),create:item==null);if(context.mounted)Navigator.pop(context,true);}catch(e){if(context.mounted)AppAlerts.error(context,e.toString());}},child:const Text('Guardar')))]),
    ])));
    if(ok==true&&context.mounted)AppAlerts.success(context,'Meta guardada');
  }
  @override Widget build(BuildContext context)=>ListView(children:[
    PageHeader(title:'Ahorro',subtitle:'Separá dinero para tus metas antes de gastarlo.',action:FilledButton.icon(onPressed:()=>form(context),icon:const Icon(Icons.add),label:const Text('Agregar'))),const SizedBox(height:20),
    if(state.goals.isEmpty)const EmptyState(title:'Sin metas',message:'Creá una meta de ahorro para reservar dinero.') else LayoutBuilder(builder:(context,c){final cols=c.maxWidth>=800?2:1;final width=(c.maxWidth-(cols-1)*12)/cols;return Wrap(spacing:12,runSpacing:12,children:state.goals.map((x){final p=x.targetAmount==0?0.0:(x.savedAmount/x.targetAmount).clamp(0.0,1.0);return SizedBox(width:width,child:Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[Expanded(child:Text(x.title,style:const TextStyle(fontSize:17,fontWeight:FontWeight.w800))),PopupMenuButton<String>(onSelected:(v) async{if(v=='edit'){form(context,item:x);}else{final ok=await AppDialogs.confirm(context,title:'Eliminar meta',message:'¿Eliminar la meta ${x.title}?');if(ok){await state.deleteGoal(x.id);if(context.mounted)AppAlerts.success(context,'Meta eliminada');}}},itemBuilder:(_)=>const [PopupMenuItem(value:'edit',child:Text('Editar')),PopupMenuItem(value:'delete',child:Text('Eliminar'))])]),
      Text('${money(x.savedAmount)} de ${money(x.targetAmount)}',style:TextStyle(color:Colors.grey.shade600)),const SizedBox(height:14),LinearProgressIndicator(value:p,minHeight:10,borderRadius:BorderRadius.circular(99)),const SizedBox(height:8),Text('${(p*100).round()}% completado',style:const TextStyle(fontWeight:FontWeight.w700)),
    ]))));}).toList());}),
  ]);
}
