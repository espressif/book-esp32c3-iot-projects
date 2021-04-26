// Copyright 2021 Espressif Systems (Shanghai) PTE LTD
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package com.espressif.cloudapi;

import com.espressif.AppConstants;
import com.google.gson.JsonObject;

import okhttp3.ResponseBody;
import retrofit2.Call;
import retrofit2.http.Body;
import retrofit2.http.DELETE;
import retrofit2.http.Field;
import retrofit2.http.FormUrlEncoded;
import retrofit2.http.GET;
import retrofit2.http.Header;
import retrofit2.http.POST;
import retrofit2.http.Url;

/**
 * This class represents interface for all APIs.
 */
public interface AlexaApiInterface {

    @POST
    Call<ResponseBody> getAlexaTokens(@Url String url, @Body JsonObject body);

    @FormUrlEncoded
    @POST
    Call<ResponseBody> getNewToken(@Url String url, @Header(AppConstants.KEY_CONTENT_TYPE) String contentType,
                                   @Field(AppConstants.KEY_GRANT_TYPE) String grantType,
                                   @Field(AppConstants.KEY_CLIENT_ID) String clientId,
                                   @Field(AppConstants.KEY_REFRESH_TOKEN) String refreshToken,
                                   @Field(AppConstants.KEY_CLIENT_SECRET) String clientSecret);

    @GET
    Call<ResponseBody> getApiEndpoints(@Url String url, @Header(AppConstants.HEADER_AUTHORIZATION) String token);

    @GET
    Call<ResponseBody> getStatus(@Url String url, @Header(AppConstants.HEADER_AUTHORIZATION) String token);

    @POST
    Call<ResponseBody> enableAlexaSkill(@Url String url, @Header(AppConstants.HEADER_AUTHORIZATION) String token, @Body JsonObject body);

    @DELETE
    Call<ResponseBody> disableAlexaSkill(@Url String url, @Header(AppConstants.HEADER_AUTHORIZATION) String token);
}
