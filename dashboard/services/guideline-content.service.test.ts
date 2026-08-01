import { afterEach, describe, expect, it, vi } from "vitest"

import { abbreviationService, guidelineCategoryService, guidelineIndexService, medicalGuidelineService } from "./guideline-content.service"

const json=(data:unknown,status=200)=>new Response(JSON.stringify({success:true,data}),{status,headers:{"Content-Type":"application/json"}})

describe("typed guideline content services",()=>{
  afterEach(()=>vi.unstubAllGlobals())

  it("uses explicit category query parameters",async()=>{
    const fetchMock=vi.fn().mockResolvedValue(json({items:[],page:1,per_page:100,total_items:0,total_pages:0}))
    vi.stubGlobal("fetch",fetchMock)
    await guidelineCategoryService.all({status:"active",parent_id:"parent-1",search:"cardio"})
    const url=String(fetchMock.mock.calls[0][0])
    expect(url).toContain("/api/v2/guideline-categories")
    expect(url).toContain("status=active")
    expect(url).toContain("parent_id=parent-1")
    expect(url).not.toContain("filter=")
  })

  it("maps compatibility form fields to typed DTOs",async()=>{
    const fetchMock=vi.fn()
      .mockResolvedValueOnce(json({id:"a-1",abbreviation:"BP",meaning:"Blood pressure",common_usage:true,categories:["cat-1"],tags:[]}))
      .mockResolvedValueOnce(json({id:"i-1",title:"Cardiology",sort_order:2,level:0,has_children:false}))
    vi.stubGlobal("fetch",fetchMock)
    await abbreviationService.create({abbreviation:"BP",meaning:"Blood pressure",category:"cat-1"})
    await guidelineIndexService.create({title:"Cardiology",parent:"",order:2})
    expect(JSON.parse(String((fetchMock.mock.calls[0][1] as RequestInit).body))).toMatchObject({categories:["cat-1"]})
    expect(JSON.parse(String((fetchMock.mock.calls[1][1] as RequestInit).body))).toMatchObject({parent_id:"",sort_order:2})
  })

  it("updates publication through the typed guideline endpoint",async()=>{
    const fetchMock=vi.fn().mockResolvedValue(json({id:"g-1",condition_name:"Example",status:"published",is_published:true}))
    vi.stubGlobal("fetch",fetchMock)
    await medicalGuidelineService.update("g-1",{is_published:true,status:"published"})
    expect(String(fetchMock.mock.calls[0][0])).toContain("/api/v2/medical-guidelines/g-1")
    expect((fetchMock.mock.calls[0][1] as RequestInit).method).toBe("PATCH")
  })
})
