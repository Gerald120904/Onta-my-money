import 'package:flutter/material.dart';
import '../providers/app_state.dart';
import '../models/models.dart';
import '../widgets/app_ui.dart';
import '../core/utils/formatters.dart';

class CommitmentsScreen extends StatelessWidget{
  final AppState state;const CommitmentsScreen({super.key,required this.state});
  Future<void> form(BuildContext context,{Commitment? item}) async{
    final key=GlobalKey<FormState>();final title=TextEditingController(text:item?.title??'');final amount=TextEditingController(text:item==null?'':item.amount.toStringAsFixed(0));
    DateTime due=item?.dueDate??DateTime.now().add(const Duration(days:7));String status=item?.status??'pending';
    final ok=await AppDialogs.form<bool>(context,title:item==null?'Nuevo compromiso':'Editar compromiso',child:StatefulBuilder(builder:(context,setLocal)=>Form(key:key,child:Column(children:[
      AppField(controller:title,label:'Nombre',validator:(v)=>(v==null||v.trim().isEmpty)?'Campo obligatorio':null),
      AppField(controller:amount,label:'Monto',keyboardType:const TextInputType.numberWithOptions(decimal:true),validator:(v)=>(double.tryParse(v??'')??0)<=0?'Monto inválido':null),
      ListTile(contentPadding:EdgeInsets.zero,title:const Text('Fecha de pago'),subtitle:Text(shortDate(due)),trailing:const Icon(Icons.calendar_month),onTap:() async{final picked=await showDatePicker(context:context,firstDate:DateTime.now().subtract(const Duration(days:365)),lastDate:DateTime.now().add(const Duration(days:3650)),initialDate:due);if(picked!=null)setLocal(()=>due=picked);}),
      DropdownButtonFormField<String>(value:status,decoration:const InputDecoration(labelText:'Estado'),items:const [DropdownMenuItem(value:'pending',child:Text('Pendiente')),DropdownMenuItem(value:'paid',child:Text('Pagado'))],onChanged:(v)=>setLocal(()=>status=v!)),
      const SizedBox(height:16),Row(children:[Expanded(child:OutlinedButton(onPressed:()=>Navigator.pop(context,false),child:const Text('Cancelar'))),const SizedBox(width:10),Expanded(child:FilledButton(onPressed:() async{
        if(!key.currentState!.validate())return;try{await state.saveCommitment(Commitment(id:item?.id??'new',title:title.text.trim(),amount:double.parse(amount.text),dueDate:due,status:status),create:item==null);if(context.mounted)Navigator.pop(context,true);}catch(e){if(context.mounted)AppAlerts.error(context,e.toString());}
      },child:const Text('Guardar')))]),
    ]))));
    if(ok==true&&context.mounted)AppAlerts.success(context,'Compromiso guardado');
  }
  @override Widget build(BuildContext context)=>ListView(children:[
    PageHeader(title:'Compromisos',subtitle:'Pagos que no deberías tocar del dinero disponible.',action:FilledButton.icon(onPressed:()=>form(context),icon:const Icon(Icons.add),label:const Text('Agregar'))),const SizedBox(height:20),
    if(state.commitments.isEmpty)const EmptyState(title:'Sin compromisos',message:'No tenés pagos pendientes registrados.') else ...state.commitments.map((x)=>Padding(padding:const EdgeInsets.only(bottom:10),child:Card(child:ListTile(
      leading:CircleAvatar(child:Icon(x.status=='paid'?Icons.check:Icons.schedule)),title:Text(x.title,style:const TextStyle(fontWeight:FontWeight.w800)),subtitle:Text('Vence ${shortDate(x.dueDate)} • ${x.status=='paid'?'Pagado':'Pendiente'}'),
      trailing:Wrap(crossAxisAlignment:WrapCrossAlignment.center,children:[Text(money(x.amount),style:const TextStyle(fontWeight:FontWeight.w900)),PopupMenuButton<String>(onSelected:(v) async{if(v=='edit'){form(context,item:x);}else{final ok=await AppDialogs.confirm(context,title:'Eliminar compromiso',message:'¿Eliminar ${x.title} por ${money(x.amount)}?');if(ok){await state.deleteCommitment(x.id);if(context.mounted)AppAlerts.success(context,'Compromiso eliminado');}}},itemBuilder:(_)=>const [PopupMenuItem(value:'edit',child:Text('Editar')),PopupMenuItem(value:'delete',child:Text('Eliminar'))])]),
    )))),
  ]);
}
