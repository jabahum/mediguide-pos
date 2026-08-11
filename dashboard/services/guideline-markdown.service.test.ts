import { afterEach, describe, expect, it, vi } from "vitest"

import { GuidelineMarkdownService } from "./guideline-markdown.service"

describe("GuidelineMarkdownService regeneration workflow", () => {
  afterEach(() => vi.unstubAllGlobals())

  it("loads authoritative revision validation", async () => {
    const fetchMock = vi.fn().mockResolvedValue(new Response(JSON.stringify({ success:true,data:{revision_id:"revision",valid:false,issues:[{severity:"error",code:"unsafe_html",message:"Unsafe",line:3,column:1,end_line:3,end_column:10}],errors:1,warnings:0,info:0} }),{status:200,headers:{"Content-Type":"application/json"}}))
    vi.stubGlobal("fetch",fetchMock)
    const result=await GuidelineMarkdownService.validate("version","revision")
    expect(result.valid).toBe(false)
    expect(fetchMock).toHaveBeenCalledWith("http://127.0.0.1:8080/api/v2/guideline-versions/version/markdown-revisions/revision/validation",expect.any(Object))
  })

  it("uses explicit cancellation and review-decision endpoints",async()=>{
    const fetchMock=vi.fn()
      .mockResolvedValueOnce(new Response(JSON.stringify({success:true,data:{id:"job",status:"cancel_requested",progress_stage:"parsing",progress_percent:20,attempt_count:0,created_at:"2026-01-01T00:00:00Z"}}),{status:200,headers:{"Content-Type":"application/json"}}))
      .mockResolvedValueOnce(new Response(JSON.stringify({success:true,data:{id:"review",version_id:"version",revision_id:"revision",job_id:"job",status:"rejected",before_snapshot:{},after_snapshot:{},comparison:{},decision_comment:"Incorrect hierarchy"}}),{status:200,headers:{"Content-Type":"application/json"}}))
    vi.stubGlobal("fetch",fetchMock)
    await GuidelineMarkdownService.cancelRegeneration("version","job")
    const review=await GuidelineMarkdownService.decideRegeneration("version","job","reject","Incorrect hierarchy")
    expect(review.status).toBe("rejected")
    expect(fetchMock).toHaveBeenNthCalledWith(2,"http://127.0.0.1:8080/api/v2/guideline-versions/version/regeneration-reviews/job/reject",expect.objectContaining({method:"POST",body:JSON.stringify({comment:"Incorrect hierarchy"})}))
  })
})
