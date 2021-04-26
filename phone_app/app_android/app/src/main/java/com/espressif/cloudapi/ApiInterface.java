// Copyright 2020 Espressif Systems (Shanghai) PTE LTD
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
import com.google.gson.JsonArray;
import com.google.gson.JsonObject;

import java.util.HashMap;

import io.reactivex.Observable;
import okhttp3.ResponseBody;
import retrofit2.Call;
import retrofit2.http.Body;
import retrofit2.http.DELETE;
import retrofit2.http.Field;
import retrofit2.http.FormUrlEncoded;
import retrofit2.http.GET;
import retrofit2.http.Header;
import retrofit2.http.POST;
import retrofit2.http.PUT;
import retrofit2.http.Query;
import retrofit2.http.Url;

/**
 * This class represents interface for all APIs.
 */
public interface ApiInterface {

    @POST
    Call<ResponseBody> login(@Url String url, @Body JsonObject body);

    @POST
    Call<ResponseBody> logout(@Url String url);

    @POST
    Call<ResponseBody> createUser(@Url String url, @Body JsonObject body);

    @POST
    Call<ResponseBody> confirmUser(@Url String url, @Body JsonObject body);

    @DELETE
    Call<ResponseBody> deleteUserRequest(@Url String url, @Header(AppConstants.HEADER_AUTHORIZATION) String token,
                                         @Query(AppConstants.KEY_REQUEST) boolean request);

    @DELETE
    Call<ResponseBody> deleteUserConfirm(@Url String url, @Header(AppConstants.HEADER_AUTHORIZATION) String token,
                                         @Query(AppConstants.KEY_VERIFICATION_CODE) String verificationCode);

    @PUT
    Call<ResponseBody> forgotPassword(@Url String url, @Body JsonObject body);

    @PUT
    Call<ResponseBody> changePassword(@Url String url, @Header(AppConstants.HEADER_AUTHORIZATION) String token,
                                      @Body JsonObject body);

    @FormUrlEncoded
    @POST
    Call<ResponseBody> oauthLogin(@Url String url, @Header("Content-type") String contentType,
                                  @Field("grant_type") String grant_type,
                                  @Field("client_id") String client_id,
                                  @Field("code") String code,
                                  @Field("redirect_uri") String redirect_uri);

    // Get Supported Versions
    @GET
    Call<ResponseBody> getSupportedVersions(@Url String url);

    // Do login (for GitHub / Google login)
    @POST
    Call<ResponseBody> getOAuthLoginToken(@Url String url, @Body HashMap<String, String> body);

    // Get Nodes
    @GET
    Call<ResponseBody> getNodes(@Url String url, @Header(AppConstants.HEADER_AUTHORIZATION) String token, @Query(AppConstants.KEY_START_ID) String startId);

    // Get Node Details
    @GET
    Call<ResponseBody> getNode(@Url String url, @Header(AppConstants.HEADER_AUTHORIZATION) String token, @Query(AppConstants.KEY_NODE_ID) String nodeId);

    // Get Node Status
    @GET
    Call<ResponseBody> getNodeStatus(@Url String url, @Header(AppConstants.HEADER_AUTHORIZATION) String token,
                                     @Query(AppConstants.KEY_NODE_ID) String nodeId);

    // Add Node
    @PUT
    Call<ResponseBody> addNode(@Url String url, @Header(AppConstants.HEADER_AUTHORIZATION) String token, @Body DeviceOperationRequest rawJsonString);

    // Get Add Node request status
    @GET
    Call<ResponseBody> getAddNodeRequestStatus(@Url String url, @Header(AppConstants.HEADER_AUTHORIZATION) String token,
                                               @Query(AppConstants.KEY_REQ_ID) String requestId, @Query(AppConstants.KEY_USER_REQUEST) boolean userReq);

    // Get param values
    @GET
    Call<ResponseBody> getParamValue(@Url String url, @Header(AppConstants.HEADER_AUTHORIZATION) String token, @Query(AppConstants.KEY_NODE_ID) String nodeId);

    // Update param value
    @PUT
    Call<ResponseBody> updateParamValue(@Url String url, @Header(AppConstants.HEADER_AUTHORIZATION) String token, @Query(AppConstants.KEY_NODE_ID) String nodeId, @Body JsonObject body);

    // Update schedules
    @PUT
    Observable<ResponseBody> updateSchedules(@Url String url, @Header(AppConstants.HEADER_AUTHORIZATION) String token, @Query(AppConstants.KEY_NODE_ID) String nodeId, @Body JsonObject body);

    // Update scenes
    @PUT
    Call<ResponseBody> updateScenes(@Url String url, @Header(AppConstants.HEADER_AUTHORIZATION) String token, @Body JsonArray body);

    // Remove Node
    @PUT
    Call<ResponseBody> removeNode(@Url String url, @Header(AppConstants.HEADER_AUTHORIZATION) String token, @Body DeviceOperationRequest rawJsonString);

    // Claiming initiate
    @POST
    Call<ResponseBody> initiateClaiming(@Url String url, @Header(AppConstants.HEADER_AUTHORIZATION) String token, @Body JsonObject body);

    // Claiming verify
    @POST
    Call<ResponseBody> verifyClaiming(@Url String url, @Header(AppConstants.HEADER_AUTHORIZATION) String token, @Body JsonObject body);

    // Feature : Node Grouping

    // Create group
    @POST
    Call<ResponseBody> createGroup(@Url String url, @Header(AppConstants.HEADER_AUTHORIZATION) String token,
                                   @Body JsonObject body);

    // Update group
    @PUT
    Call<ResponseBody> updateGroup(@Url String url, @Header(AppConstants.HEADER_AUTHORIZATION) String token,
                                   @Query(AppConstants.KEY_GROUP_ID) String groupId,
                                   @Body JsonObject body);

    // Removes group
    @DELETE
    Call<ResponseBody> removeGroup(@Url String url, @Header(AppConstants.HEADER_AUTHORIZATION) String token,
                                   @Query(AppConstants.KEY_GROUP_ID) String groupId);

    // Get user group
    @GET
    Call<ResponseBody> getUserGroups(@Url String url, @Header(AppConstants.HEADER_AUTHORIZATION) String token,
                                     @Query(AppConstants.KEY_GROUP_ID) String groupId,
                                     @Query(AppConstants.KEY_NODE_LIST) boolean shouldGetNodeList);

    // Feature : Node Sharing

    // Get sharing requests
    @GET
    Call<ResponseBody> getSharingRequests(@Url String url, @Header(AppConstants.HEADER_AUTHORIZATION) String token,
                                          @Query(AppConstants.KEY_PRIMARY_USER) boolean isPrimaryUser,
                                          @Query(AppConstants.KEY_START_REQ_ID) String startRequestId,
                                          @Query(AppConstants.KEY_START_USER_NAME) String startUserName);

    // Update sharing request
    @PUT
    Call<ResponseBody> updateSharingRequest(@Url String url, @Header(AppConstants.HEADER_AUTHORIZATION) String token,
                                            @Body JsonObject body);

    // Remove sharing request
    @DELETE
    Call<ResponseBody> removeSharingRequest(@Url String url, @Header(AppConstants.HEADER_AUTHORIZATION) String token,
                                            @Query(AppConstants.KEY_REQ_ID) String requestId);

    // Share node with the user
    @PUT
    Call<ResponseBody> shareNodeWithUser(@Url String url, @Header(AppConstants.HEADER_AUTHORIZATION) String token, @Body JsonObject body);

    // Get node sharing information
    @GET
    Call<ResponseBody> getNodeSharing(@Url String url, @Header(AppConstants.HEADER_AUTHORIZATION) String token,
                                      @Query(AppConstants.KEY_NODE_ID) String nodeId);

    // Remove the sharing of node
    @DELETE
    Call<ResponseBody> removeSharing(@Url String url, @Header(AppConstants.HEADER_AUTHORIZATION) String token,
                                     @Query(AppConstants.KEY_NODES) String nodes, @Query(AppConstants.KEY_USER_NAME) String userName);

    @POST
    Call<ResponseBody> registerDeviceToken(@Url String url, @Header(AppConstants.HEADER_AUTHORIZATION) String token,
                                           @Body JsonObject body);

    @DELETE
    Call<ResponseBody> unregisterDeviceToken(@Url String url, @Header(AppConstants.HEADER_AUTHORIZATION) String token,
                                             @Query(AppConstants.KEY_MOBILE_DEVICE_TOKEN) String deviceToken);
}
