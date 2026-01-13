const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");

// Define the secret - will be set via Firebase CLI
const geminiApiKey = defineSecret("GEMINI_API_KEY");

/**
 * Cloud Function to analyze food images OR text using Gemini API
 * This keeps the API key secure on the server side
 */
exports.analyzeFood = onCall(
    {
        secrets: [geminiApiKey],
        memory: "512MiB",
        timeoutSeconds: 60,
    },
    async (request) => {
        console.log("=== analyzeFood called ===");
        console.log("Request data keys:", Object.keys(request.data || {}));

        const { imageBase64, prompt, textOnly } = request.data || {};

        // Validate request - either image or textOnly mode required
        if (!textOnly && !imageBase64) {
            console.error("Missing imageBase64 or textOnly flag in request");
            throw new HttpsError("invalid-argument", "Image data or text prompt is required");
        }

        if (!prompt) {
            console.error("Missing prompt in request");
            throw new HttpsError("invalid-argument", "Prompt is required");
        }

        const apiKey = geminiApiKey.value();

        console.log("Text only mode:", !!textOnly);
        console.log("Image base64 length:", imageBase64?.length || 0);
        console.log("Prompt:", prompt?.substring(0, 100));
        console.log("API Key present:", !!apiKey);

        if (!apiKey) {
            console.error("API key not configured");
            throw new HttpsError("failed-precondition", "API key not configured");
        }

        try {
            console.log("Calling Gemini API...");

            // Build request body based on mode
            let requestBody;

            if (textOnly) {
                // Text-only analysis (for written food descriptions)
                requestBody = {
                    contents: [
                        {
                            role: "user",
                            parts: [{ text: prompt }],
                        },
                    ],
                    generationConfig: {
                        responseMimeType: "application/json",
                    },
                };
            } else {
                // Image analysis
                requestBody = {
                    contents: [
                        {
                            role: "user",
                            parts: [
                                { text: prompt },
                                {
                                    inlineData: {
                                        mimeType: "image/jpeg",
                                        data: imageBase64,
                                    },
                                },
                            ],
                        },
                    ],
                    generationConfig: {
                        responseMimeType: "application/json",
                    },
                };
            }

            // Call Gemini API
            const response = await fetch(
                `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${apiKey}`,
                {
                    method: "POST",
                    headers: { "Content-Type": "application/json" },
                    body: JSON.stringify(requestBody),
                }
            );

            console.log("Gemini API response status:", response.status);

            if (!response.ok) {
                const errorText = await response.text();
                console.error("Gemini API error:", response.status, errorText);
                throw new HttpsError("internal", `Gemini API error: ${response.status}`);
            }

            const data = await response.json();
            console.log("Gemini API response data:", JSON.stringify(data).substring(0, 500));

            const resultText = data.candidates?.[0]?.content?.parts?.[0]?.text;
            console.log("Result text:", resultText?.substring(0, 200));

            if (!resultText) {
                console.error("No result text from Gemini API");
                throw new HttpsError("internal", "No result from Gemini API");
            }

            // Parse and return the JSON result
            const parsedResult = JSON.parse(resultText);
            console.log("Parsed result:", JSON.stringify(parsedResult).substring(0, 200));

            return { result: parsedResult };
        } catch (error) {
            console.error("Error calling Gemini API:", error);
            if (error instanceof HttpsError) {
                throw error;
            }
            throw new HttpsError("internal", error.message || "Unknown error");
        }
    }
);
