"use client"

import { Suspense, useEffect, useState } from "react"
import Link from "next/link"
import { useSearchParams } from "next/navigation"
import { AlertCircle, CheckCircle, Loader2 } from "lucide-react"

import { Alert, AlertDescription } from "@/components/ui/alert"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardFooter, CardHeader, CardTitle } from "@/components/ui/card"
import { usersService } from "@/services/user-management.service"

function VerifyEmailContent() {
	const searchParams = useSearchParams()
	const token = searchParams.get("token")?.trim()
	const [state, setState] = useState<"loading" | "success" | "error">(
		token ? "loading" : "error",
	)

	useEffect(() => {
		if (!token) return
		usersService.confirmEmailVerification(token)
			.then(() => setState("success"))
			.catch(() => setState("error"))
	}, [token])

	return (
		<Card className="mx-auto w-full max-w-md">
			<CardHeader><CardTitle>Email verification</CardTitle></CardHeader>
			<CardContent>
				{state === "loading" && <div className="flex items-center gap-2"><Loader2 className="h-4 w-4 animate-spin" /> Verifying your email…</div>}
				{state === "success" && <Alert><CheckCircle className="h-4 w-4" /><AlertDescription>Your email has been verified.</AlertDescription></Alert>}
				{state === "error" && <Alert variant="destructive"><AlertCircle className="h-4 w-4" /><AlertDescription>This verification link is invalid, expired, or already used.</AlertDescription></Alert>}
			</CardContent>
			<CardFooter><Button asChild className="w-full"><Link href="/login">Continue to sign in</Link></Button></CardFooter>
		</Card>
	)
}

export default function VerifyEmailPage() {
	return <Suspense fallback={<Loader2 className="h-5 w-5 animate-spin" />}><VerifyEmailContent /></Suspense>
}
