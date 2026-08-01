"use client"

import { useCallback, useState } from "react"
import { useQueryClient } from "@tanstack/react-query"
import { showToast } from "@/lib/toast"

interface DomainCrud<TInput, TRecord> {
  create?: (data:TInput)=>Promise<TRecord>
  update?: (id:string,data:TInput)=>Promise<TRecord>
  delete?: (id:string)=>Promise<void>
}

export function useDomainCrud<TInput, TRecord>(domainKey:string, service:DomainCrud<TInput,TRecord>, onSuccess?:()=>void){
  const [loading,setLoading]=useState(false)
  const queryClient=useQueryClient()
  const run=useCallback(async<T,>(operation:()=>Promise<T>,message:string)=>{setLoading(true);try{const result=await operation();await queryClient.invalidateQueries({queryKey:["backend",domainKey]});showToast.success("Success",message);onSuccess?.();return result}catch(error){showToast.error("Error",error instanceof Error?error.message:"Domain operation failed");throw error}finally{setLoading(false)}},[domainKey,onSuccess,queryClient])
  return{
    loading,
    create:useCallback((data:TInput)=>{if(!service.create)throw new Error(`Create is unsupported for ${domainKey}`);return run(()=>service.create!(data),"Record created successfully")},[domainKey,run,service]),
    update:useCallback((id:string,data:TInput)=>{if(!service.update)throw new Error(`Update is unsupported for ${domainKey}`);return run(()=>service.update!(id,data),"Record updated successfully")},[domainKey,run,service]),
    deleteRecord:useCallback((id:string)=>{if(!service.delete)throw new Error(`Delete is unsupported for ${domainKey}`);return run(()=>service.delete!(id),"Record deleted successfully")},[domainKey,run,service]),
  }
}
