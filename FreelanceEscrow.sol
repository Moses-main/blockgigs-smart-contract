// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title FreelanceEscrow
 * @dev A smart contract for managing freelance jobs with escrow functionality
 * @notice This contract handles job creation, acceptance, completion, and fund release
 */
contract FreelanceEscrow {
    
    // ============ State Variables ============
    
    // Counter for generating unique job IDs
    uint256 private jobCounter;
    
    // Reentrancy guard state
    bool private locked;
    
    // ============ Enums ============
    
    /**
     * @dev Job status enumeration
     * Open: Job created and waiting for acceptance
     * Accepted: Job accepted by freelancer
     * Completed: Job marked as completed by client
     * Cancelled: Job cancelled by client (funds returned)
     * Paid: Funds released to freelancer
     */
    enum JobStatus { 
        Open, 
        Accepted, 
        Completed, 
        Cancelled, 
        Paid 
    }
    
    // ============ Structs ============
    
    /**
     * @dev Job structure containing all job-related data
     */
    struct Job {
        uint256 jobId;              // Unique job identifier
        address client;             // Address of the job creator
        address freelancer;         // Address of the assigned freelancer
        string ipfsHash;            // IPFS hash for job description/metadata
        uint256 depositAmount;      // Escrow amount deposited by client
        JobStatus status;           // Current job status
        uint256 createdAt;          // Timestamp when job was created
        bool fundsReleased;         // Flag to track if funds have been released
    }
    
    // ============ Storage ============
    
    // Mapping from job ID to Job struct
    mapping(uint256 => Job) public jobs;
    
    // Mapping to track jobs created by each client
    mapping(address => uint256[]) public clientJobs;
    
    // Mapping to track jobs assigned to each freelancer
    mapping(address => uint256[]) public freelancerJobs;
    
    // ============ Events ============
    
    /**
     * @dev Emitted when a new job is created
     */
    event JobCreated(
        uint256 indexed jobId,
        address indexed client,
        address indexed freelancer,
        string ipfsHash,
        uint256 depositAmount
    );
    
    /**
     * @dev Emitted when a job is accepted by freelancer
     */
    event JobAccepted(
        uint256 indexed jobId,
        address indexed freelancer
    );
    
    /**
     * @dev Emitted when a job is marked as completed
     */
    event JobCompleted(
        uint256 indexed jobId,
        address indexed client
    );
    
    /**
     * @dev Emitted when escrow funds are released to freelancer
     */
    event FundsReleased(
        uint256 indexed jobId,
        address indexed freelancer,
        uint256 amount
    );
    
    /**
     * @dev Emitted when a job is cancelled
     */
    event JobCancelled(
        uint256 indexed jobId,
        address indexed client,
        uint256 refundAmount
    );
    
    // ============ Modifiers ============
    
    /**
     * @dev Reentrancy guard modifier
     */
    modifier nonReentrant() {
        require(!locked, "Reentrancy detected");
        locked = true;
        _;
        locked = false;
    }
    
    /**
     * @dev Modifier to check if job exists
     */
    modifier jobExists(uint256 _jobId) {
        require(_jobId < jobCounter, "Job does not exist");
        _;
    }
    
    /**
     * @dev Modifier to check if caller is the job client
     */
    modifier onlyClient(uint256 _jobId) {
        require(jobs[_jobId].client == msg.sender, "Only job client can perform this action");
        _;
    }
    
    /**
     * @dev Modifier to check if caller is the assigned freelancer
     */
    modifier onlyFreelancer(uint256 _jobId) {
        require(jobs[_jobId].freelancer == msg.sender, "Only assigned freelancer can perform this action");
        _;
    }
    
    // ============ Constructor ============
    
    /**
     * @dev Contract constructor
     */
    constructor() {
        jobCounter = 0;
        locked = false;
    }
    
    // ============ Main Functions ============
    
    /**
     * @dev Create a new freelance job with escrow deposit
     * @param _freelancer Address of the freelancer to assign the job to
     * @param _ipfsHash IPFS hash containing job description and metadata
     * @notice Client must send ETH as deposit (msg.value > 0)
     * @return jobId The unique identifier of the created job
     */
    function createJob(
        address _freelancer,
        string memory _ipfsHash
    ) external payable returns (uint256) {
        // Input validation
        require(_freelancer != address(0), "Freelancer address cannot be zero");
        require(_freelancer != msg.sender, "Client cannot assign job to themselves");
        require(msg.value > 0, "Deposit amount must be greater than 0");
        require(bytes(_ipfsHash).length > 0, "IPFS hash cannot be empty");
        
        // Get current job ID and increment counter
        uint256 currentJobId = jobCounter;
        jobCounter++;
        
        // Create new job
        jobs[currentJobId] = Job({
            jobId: currentJobId,
            client: msg.sender,
            freelancer: _freelancer,
            ipfsHash: _ipfsHash,
            depositAmount: msg.value,
            status: JobStatus.Open,
            createdAt: block.timestamp,
            fundsReleased: false
        });
        
        // Update tracking mappings
        clientJobs[msg.sender].push(currentJobId);
        freelancerJobs[_freelancer].push(currentJobId);
        
        // Emit event
        emit JobCreated(currentJobId, msg.sender, _freelancer, _ipfsHash, msg.value);
        
        return currentJobId;
    }
    
    /**
     * @dev Accept a job (Bonus feature)
     * @param _jobId The ID of the job to accept
     * @notice Only the assigned freelancer can accept the job
     */
    function acceptJob(uint256 _jobId) 
        external 
        jobExists(_jobId) 
        onlyFreelancer(_jobId) 
    {
        Job storage job = jobs[_jobId];
        
        // Check job status
        require(job.status == JobStatus.Open, "Job is not available for acceptance");
        
        // Update job status
        job.status = JobStatus.Accepted;
        
        // Emit event
        emit JobAccepted(_jobId, msg.sender);
    }
    
    /**
     * @dev Mark a job as completed
     * @param _jobId The ID of the job to mark as completed
     * @notice Only the job client can mark job as completed
     */
    function completeJob(uint256 _jobId) 
        external 
        jobExists(_jobId) 
        onlyClient(_jobId) 
    {
        Job storage job = jobs[_jobId];
        
        // Check job status (can be completed from Open or Accepted status)
        require(
            job.status == JobStatus.Open || job.status == JobStatus.Accepted, 
            "Job cannot be completed in current status"
        );
        
        // Update job status
        job.status = JobStatus.Completed;
        
        // Emit event
        emit JobCompleted(_jobId, msg.sender);
    }
    
    /**
     * @dev Release escrow funds to the freelancer
     * @param _jobId The ID of the job to release funds for
     * @notice Only client can release funds and only for completed jobs
     */
    function releaseFunds(uint256 _jobId) 
        external 
        nonReentrant 
        jobExists(_jobId) 
        onlyClient(_jobId) 
    {
        Job storage job = jobs[_jobId];
        
        // Validate conditions for fund release
        require(job.status == JobStatus.Completed, "Job must be completed before releasing funds");
        require(!job.fundsReleased, "Funds have already been released");
        require(job.depositAmount > 0, "No funds to release");
        
        // Update state before external call (CEI pattern)
        job.fundsReleased = true;
        job.status = JobStatus.Paid;
        uint256 amount = job.depositAmount;
        
        // Transfer funds to freelancer
        (bool success, ) = payable(job.freelancer).call{value: amount}("");
        require(success, "Fund transfer failed");
        
        // Emit event
        emit FundsReleased(_jobId, job.freelancer, amount);
    }
    
    /**
     * @dev Cancel a job and refund the client (Bonus feature)
     * @param _jobId The ID of the job to cancel
     * @notice Only client can cancel and only before job acceptance
     */
    function cancelJob(uint256 _jobId) 
        external 
        nonReentrant 
        jobExists(_jobId) 
        onlyClient(_jobId) 
    {
        Job storage job = jobs[_jobId];
        
        // Check if job can be cancelled
        require(job.status == JobStatus.Open, "Job can only be cancelled if not yet accepted");
        require(!job.fundsReleased, "Cannot cancel job with released funds");
        
        // Update state before external call (CEI pattern)
        job.status = JobStatus.Cancelled;
        uint256 refundAmount = job.depositAmount;
        job.depositAmount = 0; // Prevent double withdrawal
        
        // Refund the client
        (bool success, ) = payable(job.client).call{value: refundAmount}("");
        require(success, "Refund transfer failed");
        
        // Emit event
        emit JobCancelled(_jobId, msg.sender, refundAmount);
    }
    
    // ============ View Functions ============
    
    // /**
    //  * @dev Get job details by ID
    //  * @param _jobId The ID of the job
    //  * @return All job details
    //  */
    function getJob(uint256 _jobId) 
        external 
        view 
        jobExists(_jobId) 
        returns (
            uint256 jobId,
            address client,
            address freelancer,
            string memory ipfsHash,
            uint256 depositAmount,
            JobStatus status,
            uint256 createdAt,
            bool fundsReleased
        ) 
    {
        Job memory job = jobs[_jobId];
        return (
            job.jobId,
            job.client,
            job.freelancer,
            job.ipfsHash,
            job.depositAmount,
            job.status,
            job.createdAt,
            job.fundsReleased
        );
    }
    
    /**
     * @dev Get total number of jobs created
     * @return Total job count
     */
    function getTotalJobs() external view returns (uint256) {
        return jobCounter;
    }
    
    /**
     * @dev Get jobs created by a specific client
     * @param _client Address of the client
     * @return Array of job IDs
     */
    function getClientJobs(address _client) external view returns (uint256[] memory) {
        return clientJobs[_client];
    }
    
    /**
     * @dev Get jobs assigned to a specific freelancer
     * @param _freelancer Address of the freelancer
     * @return Array of job IDs
     */
    function getFreelancerJobs(address _freelancer) external view returns (uint256[] memory) {
        return freelancerJobs[_freelancer];
    }
    
    /**
     * @dev Get contract balance
     * @return Contract's ETH balance
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

        // Freelancer can view available jobs assigned to them but not accepted yet
    function getPendingJobsForFreelancer(address _freelancer) external view returns (uint256[] memory) {
        uint256[] memory allJobs = freelancerJobs[_freelancer];
        uint256 count = 0;

        // First pass to count pending jobs
        for (uint256 i = 0; i < allJobs.length; i++) {
            if (jobs[allJobs[i]].status == JobStatus.Open) {
                count++;
            }
        }

        // Second pass to collect job IDs
        uint256[] memory pending = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < allJobs.length; i++) {
            if (jobs[allJobs[i]].status == JobStatus.Open) {
                pending[index++] = allJobs[i];
            }
        }

        return pending;
    }

    
    // ============ Emergency Functions ============
    
    /**
     * @dev Emergency function to check if contract is locked (for debugging)
     * @return Current lock status
     */
    function isLocked() external view returns (bool) {
        return locked;
    }
}