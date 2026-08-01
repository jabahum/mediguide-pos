"use client"

import { useQuery } from "@tanstack/react-query"

export function useDomainRecord<T>(domainKey:string,id:string,load:(id:string)=>Promise<T>){
  const query=useQuery({queryKey:["backend",domainKey,"record",id],queryFn:()=>load(id),enabled:Boolean(id)})
  return{record:query.data??null,loading:query.isPending,error:query.error??null,refresh:query.refetch}
}
